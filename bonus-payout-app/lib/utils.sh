#!/opt/homebrew/bin/bash

# Utility functions for Bonus Payout Application
# Input validation, formatting, and helper functions

# Validate email address format
validate_email() {
    local email="$1"
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    if [[ $email =~ $email_regex ]]; then
        return 0
    else
        echo -e "${RED}Invalid email format: $email${NC}"
        return 1
    fi
}

# Validate wallet address format (basic validation)
validate_wallet_address() {
    local address="$1"
    
    # Basic Ethereum address validation (42 characters, starts with 0x)
    if [[ ${#address} -eq 42 ]] && [[ $address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0
    elif [[ ${#address} -ge 26 ]] && [[ ${#address} -le 62 ]]; then
        # Basic validation for other address formats (Bitcoin, etc.)
        return 0
    else
        echo -e "${RED}Invalid wallet address format: $address${NC}"
        echo "Address should be a valid cryptocurrency wallet address"
        return 1
    fi
}

# Validate amount (numeric and positive)
validate_amount() {
    local amount="$1"
    
    if [[ $amount =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$amount > 0" | bc -l) )); then
        return 0
    else
        echo -e "${RED}Invalid amount: $amount${NC}"
        echo "Amount must be a positive number"
        return 1
    fi
}

# Validate cryptocurrency symbol
validate_crypto_symbol() {
    local symbol="$1"
    local valid_symbols=("USDC" "USDT" "ETH" "BTC" "BNB" "MATIC" "DAI")
    
    # Convert to uppercase
    symbol=$(echo "$symbol" | tr '[:lower:]' '[:upper:]')
    
    for valid_symbol in "${valid_symbols[@]}"; do
        if [[ "$symbol" == "$valid_symbol" ]]; then
            return 0
        fi
    done
    
    echo -e "${RED}Invalid cryptocurrency symbol: $symbol${NC}"
    echo "Supported symbols: ${valid_symbols[*]}"
    return 1
}

# Validate all payout inputs
validate_payout_inputs() {
    local email="$1"
    local address="$2"
    local amount="$3"
    local symbol="$4"
    
    local valid=true
    
    if ! validate_email "$email"; then
        valid=false
    fi
    
    if ! validate_wallet_address "$address"; then
        valid=false
    fi
    
    if ! validate_amount "$amount"; then
        valid=false
    fi
    
    if ! validate_crypto_symbol "$symbol"; then
        valid=false
    fi
    
    if [[ "$valid" == "true" ]]; then
        return 0
    else
        echo -e "${RED}Validation failed. Please correct the errors above.${NC}"
        return 1
    fi
}

# Format amount with proper decimal places
format_amount() {
    local amount="$1"
    local symbol="$2"
    
    case "${symbol^^}" in
        "USDC"|"USDT"|"DAI")
            printf "%.2f" "$amount"
            ;;
        "ETH"|"BTC")
            printf "%.6f" "$amount"
            ;;
        "BNB"|"MATIC")
            printf "%.4f" "$amount"
            ;;
        *)
            printf "%.4f" "$amount"
            ;;
    esac
}

# Generate transaction ID
generate_transaction_id() {
    local prefix="$1"
    local timestamp=$(date +%s)
    local random=$(shuf -i 1000-9999 -n 1)
    echo "${prefix}_${timestamp}_${random}"
}

# Format date for display
format_date() {
    local timestamp="$1"
    date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S'
}

# Convert amount to different currencies (mock function)
convert_currency() {
    local amount="$1"
    local from_currency="$2"
    local to_currency="$3"
    
    # Mock conversion rates (in production, use real API)
    case "${from_currency^^}_${to_currency^^}" in
        "USD_USDC"|"USD_USDT")
            echo "$amount"
            ;;
        "USD_ETH")
            echo "scale=6; $amount / 2500" | bc -l
            ;;
        "USD_BTC")
            echo "scale=8; $amount / 45000" | bc -l
            ;;
        *)
            echo "$amount"
            ;;
    esac
}

# Check if file exists and is readable
check_file_readable() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        echo -e "${RED}File not readable: $file${NC}"
        return 1
    fi
    
    return 0
}

# Validate CSV file format
validate_csv_format() {
    local csv_file="$1"
    
    if ! check_file_readable "$csv_file"; then
        return 1
    fi
    
    # Check if header exists
    local header=$(head -n 1 "$csv_file")
    local expected_header="email,wallet_address,amount,crypto_symbol,network,description"
    
    if [[ "$header" != "$expected_header" ]]; then
        echo -e "${RED}Invalid CSV format${NC}"
        echo "Expected header: $expected_header"
        echo "Found header: $header"
        return 1
    fi
    
    # Check if file has data rows
    local row_count=$(wc -l < "$csv_file")
    if [[ $row_count -lt 2 ]]; then
        echo -e "${RED}CSV file has no data rows${NC}"
        return 1
    fi
    
    echo -e "${GREEN}CSV format is valid ($((row_count - 1)) data rows)${NC}"
    return 0
}

# Create sample CSV file
create_sample_csv() {
    local filename="$1"
    
    cat > "$filename" << EOF
email,wallet_address,amount,crypto_symbol,network,description
john.doe@example.com,0x742d35Cc6634C0532925a3b8D66C2dDc168E7d8f,100.00,USDC,Ethereum,Q4 Performance Bonus
jane.smith@example.com,0x8ba1f109551bD432803012645Hac136c5a765a13,250.50,USDT,Ethereum,Sales Target Achievement
bob.wilson@example.com,0x1234567890abcdef1234567890abcdef12345678,75.25,USDC,Polygon,Project Completion Bonus
EOF
    
    echo -e "${GREEN}Sample CSV file created: $filename${NC}"
    echo "You can edit this file with your actual payout data."
}

# Ask for confirmation
ask_confirmation() {
    local message="$1"
    echo -n "$message (y/N): "
    read -n 1 confirmation
    echo ""
    
    case "$confirmation" in
        [yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\rProgress: ["
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' '-'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

# Clean up temporary files
cleanup_temp_files() {
    local temp_dir="$SCRIPT_DIR/tmp"
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"/*
        echo "Temporary files cleaned up"
    fi
}

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root is not recommended for security reasons.${NC}"
        if ! ask_confirmation "Continue anyway?"; then
            echo "Exiting..."
            exit 1
        fi
    fi
}

# Backup configuration files
backup_config() {
    local backup_dir="$SCRIPT_DIR/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_dir/.env_backup_$timestamp"
        echo "Configuration backed up to: $backup_dir/.env_backup_$timestamp"
    fi
}

# Initialize utilities
init_utils() {
    # Create temporary directory if needed
    mkdir -p "$SCRIPT_DIR/tmp"
    
    # Check for required commands
    for cmd in bc date; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${YELLOW}Warning: $cmd command not found. Some features may not work properly.${NC}"
        fi
    done
}

# Initialize utilities on load
init_utils 