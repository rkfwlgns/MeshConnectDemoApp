#!/opt/homebrew/bin/bash

# MeshConnect API interaction functions
# Handles authentication, transfers, and account management

# Check if curl and jq are available
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required but not installed.${NC}"
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq is recommended for better JSON parsing.${NC}"
        echo "Installing jq via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo -e "${RED}Please install jq manually: brew install jq${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Make authenticated API request with MeshConnect headers
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local base_url=$(get_api_base_url)
    
    # Get authentication headers
    local auth_headers=$(get_auth_headers)
    
    if [[ -z "$auth_headers" ]]; then
        echo -e "${RED}Authentication failed. Please check your API credentials.${NC}"
        return 1
    fi
    
    # Parse auth headers into separate variables
    local client_id_header=$(echo "$auth_headers" | grep "X-Client-Id:")
    local client_secret_header=$(echo "$auth_headers" | grep "X-Client-Secret:")
    
    # Debug output (remove in production)
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "DEBUG: Making API request to ${base_url}${endpoint}"
        echo "DEBUG: Method: $method"
        echo "DEBUG: Headers: $client_id_header, $client_secret_header"
        if [[ -n "$data" ]]; then
            echo "DEBUG: Payload: $data"
        fi
    fi
    
    local curl_opts=(
        -s
        -X "$method"
        -H "$client_id_header"
        -H "$client_secret_header"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )
    
    if [[ -n "$data" ]]; then
        curl_opts+=(-d "$data")
    fi
    
    local response=$(curl "${curl_opts[@]}" "${base_url}${endpoint}")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}API request failed (curl exit code: $exit_code)${NC}"
        return 1
    fi
    
    # Debug output (remove in production)
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "DEBUG: Raw response: $response"
    fi
    
    # Clean up response - sometimes we get duplicate JSON objects
    # Extract only the first valid JSON object by finding the first complete JSON
    if [[ "$response" == *"}{"* ]]; then
        # Multiple JSON objects detected, take the first one
        local first_json=$(echo "$response" | sed 's/}{.*/}/')
        echo "$first_json"
    else
        echo "$response"
    fi
    return 0
}

# Test API connection
test_api_connection() {
    echo "Testing API connection..."
    
    if ! check_dependencies; then
        return 1
    fi
    
    # Create a simple link token request to test connection
    local test_payload='{
        "userId": "test_connection_'"$(date +%s)"'",
        "restrictMultipleAccounts": false
    }'
    
    local response=$(api_request "POST" "/api/v1/linktoken" "$test_payload")
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ API connection successful${NC}"
        if command -v jq &> /dev/null; then
            echo "Response preview:"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
        fi
        log_info "API connection test successful"
        return 0
    else
        echo -e "${RED}✗ API connection failed${NC}"
        echo "Response: $response"
        log_error "API connection test failed: $response"
        return 1
    fi
}

# Get account balance
get_account_balance() {
    echo "Fetching account balance..."
    
    if ! check_dependencies; then
        return 1
    fi
    
    # First, we need to create a link token to get access to account information
    local link_token_response=$(create_link_token_for_balance)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to create link token for balance check${NC}"
        echo "Response: $link_token_response"
        return 1
    fi
    
    if command -v jq &> /dev/null; then
        local link_token=$(echo "$link_token_response" | jq -r '.content.linkToken // empty')
        
        if [[ -n "$link_token" ]]; then
            echo -e "${GREEN}Link token created successfully${NC}"
            echo "Use this token in your frontend to connect accounts and check balances"
            echo "Link Token: $link_token"
        else
            echo -e "${YELLOW}Balance check requires user to connect their account first${NC}"
            echo "Please use the MeshConnect Link UI to connect a Coinbase account"
            echo "Full response: $link_token_response"
        fi
    else
        echo "Raw response:"
        echo "$link_token_response"
    fi
    
    log_info "Balance check initiated"
    return 0
}

# Create link token for balance checking
create_link_token_for_balance() {
    local payload=$(cat <<EOF
{
    "userId": "bonus_payout_user_$(date +%s)",
    "restrictMultipleAccounts": false,
    "transferOptions": {
        "transactionId": "balance_check_$(date +%s)",
        "transferType": "deposit",
        "toAddresses": []
    }
}
EOF
)
    
    api_request "POST" "/api/v1/linktoken" "$payload"
}

# Create link token for payout
create_link_token_for_payout() {
    local recipient_address="$1"
    local amount="$2"
    local symbol="$3"
    local network_id="$4"
    local transaction_id="$5"
    
    local payload=$(cat <<EOF
{
    "userId": "payout_user_$(date +%s)",
    "restrictMultipleAccounts": true,
    "transferOptions": {
        "transactionId": "$transaction_id",
        "transferType": "payment",
        "fundingOptions": {
            "enabled": true
        },
        "isInclusiveFeeEnabled": false,
        "toAddresses": [
            {
                "symbol": "$symbol",
                "address": "$recipient_address",
                "networkId": "$network_id",
                "amount": $amount
            }
        ]
    }
}
EOF
)
    
    api_request "POST" "/api/v1/linktoken" "$payload"
}

# Get network ID for a given network name
get_network_id() {
    local network_name="$1"
    
    # Common network IDs (these would typically come from the API documentation)
    case "${network_name,,}" in
        "ethereum")
            echo "e3c7fdd8-b1fc-4e51-85ae-bb276e075611"
            ;;
        "polygon")
            echo "18fa36b0-88a8-43ca-83db-9a874e0a2288"
            ;;
        "bsc"|"binance smart chain")
            echo "5a2e7b18-c95b-4b2f-8b1a-9d8e7c4f3a2b"
            ;;
        *)
            echo "e3c7fdd8-b1fc-4e51-85ae-bb276e075611" # Default to Ethereum
            ;;
    esac
}

# Process a single payout
process_payout() {
    local recipient_email="$1"
    local recipient_address="$2"
    local amount="$3"
    local symbol="$4"
    local network_name="$5"
    local description="$6"
    
    echo "Processing payout..."
    echo "Recipient: $recipient_email"
    echo "Address: $recipient_address"
    echo "Amount: $amount $symbol"
    echo "Network: $network_name"
    echo "Description: $description"
    echo ""
    
    local network_id=$(get_network_id "$network_name")
    local transaction_id="bonus_$(date +%s)_$(echo $recipient_email | cut -d'@' -f1)"
    
    echo "Creating link token for payout..."
    local response=$(create_link_token_for_payout "$recipient_address" "$amount" "$symbol" "$network_id" "$transaction_id")
    
    if [[ $? -eq 0 ]]; then
        if command -v jq &> /dev/null; then
            local link_token=$(echo "$response" | jq -r '.content.linkToken // empty')
            
            if [[ -n "$link_token" ]]; then
                echo -e "${GREEN}✓ Payout link token created successfully${NC}"
                echo ""
                echo "=== PAYOUT INSTRUCTIONS ==="
                echo "1. Copy the link token below"
                echo "2. Run: ./serve-web-interface.sh"
                echo "3. Open your browser to the displayed URL"
                echo "4. Paste the link token and click 'Process Payment'"
                echo ""
                echo "Link Token:"
                echo "$link_token"
                echo ""
                
                # Log the payout
                log_payout "$recipient_email" "$recipient_address" "$amount" "$symbol" "$network_name" "$description" "$link_token" "INITIATED"
                
                return 0
            else
                echo -e "${RED}✗ Failed to extract link token from response${NC}"
                echo "Raw response: $response"
                
                # Check if the response contains an error
                if command -v jq &> /dev/null; then
                    local error_message=$(echo "$response" | jq -r '.message // empty')
                    local error_type=$(echo "$response" | jq -r '.errorType // empty')
                    if [[ -n "$error_message" ]]; then
                        echo "Error message: $error_message"
                    fi
                    if [[ -n "$error_type" ]]; then
                        echo "Error type: $error_type"
                    fi
                fi
                
                log_error "Failed to create payout link token for $recipient_email: $response"
                return 1
            fi
        else
            echo "Link token response (jq not available):"
            echo "$response"
            log_payout "$recipient_email" "$recipient_address" "$amount" "$symbol" "$network_name" "$description" "N/A" "INITIATED"
        fi
    else
        echo -e "${RED}✗ Failed to create payout link token${NC}"
        echo "Response: $response"
        log_error "Failed to create payout link token for $recipient_email: $response"
        return 1
    fi
}

# Process batch payouts from CSV
process_batch_payouts_from_csv() {
    local csv_file="$1"
    local processed=0
    local failed=0
    
    echo "Processing batch payouts from: $csv_file"
    echo ""
    
    # Skip header line and process each row
    tail -n +2 "$csv_file" | while IFS=',' read -r email address amount symbol network description; do
        # Remove quotes and whitespace
        email=$(echo "$email" | tr -d '"' | xargs)
        address=$(echo "$address" | tr -d '"' | xargs)
        amount=$(echo "$amount" | tr -d '"' | xargs)
        symbol=$(echo "$symbol" | tr -d '"' | xargs)
        network=$(echo "$network" | tr -d '"' | xargs)
        description=$(echo "$description" | tr -d '"' | xargs)
        
        echo "Processing: $email ($amount $symbol)"
        
        if validate_payout_inputs "$email" "$address" "$amount" "$symbol"; then
            if process_payout "$email" "$address" "$amount" "$symbol" "$network" "$description"; then
                ((processed++))
                echo -e "${GREEN}✓ Processed successfully${NC}"
            else
                ((failed++))
                echo -e "${RED}✗ Processing failed${NC}"
            fi
        else
            ((failed++))
            echo -e "${RED}✗ Validation failed${NC}"
        fi
        
        echo "---"
        sleep 1 # Rate limiting
    done
    
    echo ""
    echo "Batch processing complete:"
    echo "Processed: $processed"
    echo "Failed: $failed"
    
    log_info "Batch processing complete: $processed processed, $failed failed"
}

# Initialize API dependencies
check_dependencies 