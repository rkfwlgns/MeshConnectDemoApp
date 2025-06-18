#!/bin/bash

# Portfolio Reader Script - Read Coinbase portfolio data via MeshConnect API
# Uses stored access tokens from previous connections

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load configuration and functions
source ./lib/config.sh
source ./lib/api.sh
source ./lib/utils.sh
source ./lib/logging.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}         Coinbase Portfolio Reader${NC}"
echo -e "${BLUE}         Via MeshConnect API${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check configuration
if ! check_config; then
    echo -e "${RED}Please configure API credentials first using: ./bonus-payout.sh${NC}"
    exit 1
fi

# Function to read stored access tokens
read_stored_tokens() {
    local token_file="$HOME/.mesh_access_tokens"
    
    if [[ ! -f "$token_file" ]]; then
        echo -e "${YELLOW}No stored access tokens found.${NC}"
        echo "You need to connect to Coinbase first via the web interface."
        echo "Run a bonus payment and complete the connection process."
        return 1
    fi
    
    echo -e "${GREEN}Found stored access tokens!${NC}"
    return 0
}

# Function to fetch portfolio data
fetch_portfolio_data() {
    local access_token="$1"
    local broker_name="$2"
    local account_id="$3"
    
    echo -e "${CYAN}📊 Fetching portfolio data for ${broker_name}...${NC}"
    
    # Make API call to get account data
    local response=$(curl -s \
        -H "Authorization: Bearer ${access_token}" \
        -H "Content-Type: application/json" \
        -H "X-Client-Id: ${MESH_CLIENT_ID}" \
        -H "X-Client-Secret: ${MESH_CLIENT_SECRET}" \
        "${MESH_BASE_URL}/api/v1/accounts")
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        echo -e "${GREEN}✅ Portfolio data retrieved successfully!${NC}"
        echo ""
        display_portfolio_data "$response" "$broker_name" "$account_id"
    else
        echo -e "${RED}❌ Failed to fetch portfolio data${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Function to display portfolio data
display_portfolio_data() {
    local data="$1"
    local broker_name="$2"
    local account_id="$3"
    
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}         PORTFOLIO SUMMARY${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    # Display broker info
    echo -e "${CYAN}🏦 Account Information:${NC}"
    echo "   • Broker: $broker_name"
    echo "   • Account ID: $account_id"
    echo "   • Connection Status: ✅ Connected"
    echo ""
    
    # Try to parse JSON data
    if command -v jq &> /dev/null; then
        echo -e "${CYAN}💰 Account Balances:${NC}"
        
        # Extract accounts if they exist
        local accounts=$(echo "$data" | jq -r '.accounts[]? // empty')
        
        if [[ -n "$accounts" ]]; then
            echo "$data" | jq -r '.accounts[] | "   • \(.name // "Account"): \(.balance // "N/A") \(.currency // "USD")"'
        else
            echo "   No detailed balance information available"
            echo "   (This may require additional API permissions)"
        fi
        
        echo ""
        echo -e "${CYAN}📊 Raw Portfolio Response:${NC}"
        echo "$data" | jq '.' 2>/dev/null || echo "$data"
        
    else
        echo -e "${CYAN}💰 Raw Portfolio Data:${NC}"
        echo "$data"
        echo ""
        echo -e "${YELLOW}💡 Install 'jq' for better JSON formatting: brew install jq${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}================================================${NC}"
}

# Function to list stored connections
list_connections() {
    echo -e "${CYAN}🔗 Checking for stored Coinbase connections...${NC}"
    echo ""
    
    # Check web interface storage (simulated)
    echo "Looking for stored access tokens from previous connections..."
    echo ""
    
    # In a real implementation, you would read from the same storage
    # that the web interface uses. For now, we'll show instructions.
    echo -e "${YELLOW}📋 To view portfolio data:${NC}"
    echo "1. Complete a bonus payment via the web interface"
    echo "2. Connect to your Coinbase account during the process"
    echo "3. The access token will be stored for future use"
    echo "4. This script will then be able to read your portfolio"
    echo ""
    
    echo -e "${BLUE}💡 Alternative: Use Web Interface${NC}"
    echo "• Open: http://localhost:3000/web-interface-simple.html"
    echo "• Click: '📊 View Portfolio' button"
    echo "• This provides real-time portfolio viewing"
}

# Function to test API connectivity
test_api_connection() {
    echo -e "${CYAN}🧪 Testing MeshConnect API connectivity...${NC}"
    
    local test_response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "X-Client-Id: ${MESH_CLIENT_ID}" \
        -H "X-Client-Secret: ${MESH_CLIENT_SECRET}" \
        "${MESH_BASE_URL}/api/v1/linktoken")
    
    if [[ "$test_response" == "200" ]] || [[ "$test_response" == "400" ]]; then
        echo -e "${GREEN}✅ API connection successful!${NC}"
        echo "   HTTP Status: $test_response"
        return 0
    else
        echo -e "${RED}❌ API connection failed${NC}"
        echo "   HTTP Status: $test_response"
        return 1
    fi
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}Portfolio Reader Menu:${NC}"
        echo "1. 📊 Read Portfolio Data"
        echo "2. 🔗 List Stored Connections"
        echo "3. 🧪 Test API Connection"
        echo "4. 🌐 Open Web Interface"
        echo "5. 📚 Help & Instructions"
        echo "6. 🚪 Exit"
        echo ""
        
        read -p "Please select an option (1-6): " choice
        
        case $choice in
            1)
                echo ""
                list_connections
                ;;
            2)
                echo ""
                list_connections
                ;;
            3)
                echo ""
                test_api_connection
                ;;
            4)
                echo ""
                echo -e "${CYAN}🌐 Opening web interface...${NC}"
                echo "URL: http://localhost:3000/web-interface-simple.html"
                echo ""
                if command -v open &> /dev/null; then
                    open "http://localhost:3000/web-interface-simple.html"
                else
                    echo "Please open the URL manually in your browser."
                fi
                ;;
            5)
                show_help
                ;;
            6)
                echo ""
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-6.${NC}"
                ;;
        esac
    done
}

# Help function
show_help() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}           PORTFOLIO READER HELP${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    echo -e "${CYAN}🎯 Purpose:${NC}"
    echo "This script reads Coinbase portfolio data using MeshConnect API"
    echo "after you've established a connection via the bonus payment process."
    echo ""
    
    echo -e "${CYAN}📋 How to Use:${NC}"
    echo "1. First, complete a bonus payment using ./bonus-payout.sh"
    echo "2. During payment, connect to your Coinbase account"
    echo "3. The connection creates an access token for future use"
    echo "4. This script uses that token to read portfolio data"
    echo ""
    
    echo -e "${CYAN}🌐 Web Interface Alternative:${NC}"
    echo "• Open: http://localhost:3000/web-interface-simple.html"
    echo "• Click: '📊 View Portfolio' button"
    echo "• Real-time portfolio viewing with better formatting"
    echo ""
    
    echo -e "${CYAN}🔧 Troubleshooting:${NC}"
    echo "• No stored tokens: Complete a payment first to connect"
    echo "• API errors: Check your MeshConnect API credentials"
    echo "• Network issues: Test API connection (option 3)"
    echo "• Permission errors: Ensure Coinbase account allows API access"
    echo ""
    
    echo -e "${CYAN}📊 What You'll See:${NC}"
    echo "• Connected account information"
    echo "• Available balances by currency"
    echo "• Account types and status"
    echo "• Raw API response data"
}

# Start the script
echo -e "${CYAN}Welcome to the Coinbase Portfolio Reader!${NC}"
echo "This tool reads your portfolio data via MeshConnect API."
echo ""

# Run main menu
main_menu 