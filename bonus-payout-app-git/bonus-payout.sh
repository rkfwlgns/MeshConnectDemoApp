#!/bin/bash

# Bonus Payout Application using MeshConnect & Coinbase
# Main entry point script

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create lib directory if it doesn't exist
mkdir -p lib logs data

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
NC='\033[0m' # No Color

# Application header
show_header() {
    clear
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}         Bonus Payout Application${NC}"
    echo -e "${BLUE}         Powered by MeshConnect${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

# Main menu
show_menu() {
    echo -e "${YELLOW}Main Menu:${NC}"
    echo "1. Setup API Configuration"
    echo "2. View Available Balance"
    echo "3. Process Single Bonus Payout"
    echo "4. Process Batch Bonus Payouts"
    echo "5. View Payout History"
    echo "6. View Supported Networks & Tokens"
    echo "7. Test Connection"
    echo "8. Exit"
    echo ""
    echo -n "Please select an option (1-8): "
}

# Setup API configuration
setup_api_config() {
    echo -e "${YELLOW}Setting up API Configuration...${NC}"
    echo ""
    
    echo "Choose environment:"
    echo "1. Sandbox (for testing)"
    echo "2. Production"
    echo -n "Select environment (1-2): "
    read env_choice
    
    case $env_choice in
        1)
            export MESH_ENV="sandbox"
            echo "Selected: Sandbox environment"
            ;;
        2)
            export MESH_ENV="production"
            echo "Selected: Production environment"
            ;;
        *)
            echo -e "${RED}Invalid choice. Defaulting to sandbox.${NC}"
            export MESH_ENV="sandbox"
            ;;
    esac
    
    echo ""
    echo -n "Enter your MeshConnect Provided ClientID: "
    read -s api_key
    echo ""
    echo -n "Enter your MeshConnect Provided API Key: "
    read -s api_secret
    echo ""
    
    # Save configuration
    save_config "MESH_API_KEY" "$api_key"
    save_config "MESH_API_SECRET" "$api_secret"
    save_config "MESH_ENV" "$MESH_ENV"
    
    echo -e "${GREEN}Configuration saved successfully!${NC}"
    log_info "API configuration updated for $MESH_ENV environment"
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# View available balance
view_balance() {
    echo -e "${YELLOW}Checking Available Balance...${NC}"
    echo ""
    
    if ! check_config; then
        echo -e "${RED}Please setup API configuration first.${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    # Get balance from MeshConnect API
    get_account_balance
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# Process single bonus payout
process_single_payout() {
    echo -e "${YELLOW}Processing Single Bonus Payout...${NC}"
    echo ""
    
    if ! check_config; then
        echo -e "${RED}Please setup API configuration first.${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    echo -n "Enter recipient email: "
    read recipient_email
    echo -n "Enter recipient wallet address: "
    read recipient_address
    echo -n "Enter bonus amount (USD): "
    read bonus_amount
    echo -n "Enter cryptocurrency (USDC/USDT/ETH): "
    read crypto_symbol
    echo -n "Enter network (Ethereum/Polygon/etc): "
    read network_name
    echo -n "Enter bonus description: "
    read description
    
    # Validate inputs
    if ! validate_payout_inputs "$recipient_email" "$recipient_address" "$bonus_amount" "$crypto_symbol"; then
        echo "Press Enter to continue..."
        read
        return
    fi
    
    # Process the payout
    process_payout "$recipient_email" "$recipient_address" "$bonus_amount" "$crypto_symbol" "$network_name" "$description"
    
    echo ""
    echo -e "${GREEN}Press Enter to open the web interface to complete your payment...${NC}"
    read
    
    # Open web interface for payment completion
    echo -e "${CYAN}🌐 Opening web interface...${NC}"
    local web_url="http://localhost:3001/web-interface-simple.html"
    
    if command -v open &> /dev/null; then
        # macOS
        open "$web_url"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$web_url"
    elif command -v start &> /dev/null; then
        # Windows
        start "$web_url"
    else
        echo "Please manually open: $web_url"
    fi
    
    echo -e "${YELLOW}💡 Instructions:${NC}"
    echo "1. Copy the link token from above"
    echo "2. Paste it in the web interface"
    echo "3. Click 'Complete Bonus Payment'"
    echo "4. Connect to Coinbase and complete the transfer"
    echo ""
    echo "Press Enter when you've completed the web payment..."
    read
}

# Process batch bonus payouts
process_batch_payouts() {
    echo -e "${YELLOW}Processing Batch Bonus Payouts...${NC}"
    echo ""
    
    if ! check_config; then
        echo -e "${RED}Please setup API configuration first.${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    echo "Batch payout requires a CSV file with the following columns:"
    echo "email,wallet_address,amount,crypto_symbol,network,description"
    echo ""
    echo -n "Enter path to CSV file: "
    read csv_file
    
    if [[ ! -f "$csv_file" ]]; then
        echo -e "${RED}File not found: $csv_file${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    process_batch_payouts_from_csv "$csv_file"
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# View payout history
view_payout_history() {
    echo -e "${YELLOW}Payout History:${NC}"
    echo ""
    
    if [[ -f "$LOG_DIR/payouts.log" ]]; then
        echo "Recent payouts:"
        echo "----------------------------------------"
        tail -20 "$LOG_DIR/payouts.log" | while read line; do
            echo "$line"
        done
    else
        echo "No payout history found."
    fi
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# View supported networks and tokens
view_supported_networks() {
    echo -e "${YELLOW}Supported Networks & Tokens:${NC}"
    echo ""
    
    if ! check_config; then
        echo -e "${RED}Please setup API configuration first.${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    get_supported_networks
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# Test connection
test_connection() {
    echo -e "${YELLOW}Testing Connection...${NC}"
    echo ""
    
    if ! check_config; then
        echo -e "${RED}Please setup API configuration first.${NC}"
        echo "Press Enter to continue..."
        read
        return
    fi
    
    test_api_connection
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# Main application loop
main() {
    # Initialize logging
    init_logging
    
    while true; do
        show_header
        show_menu
        read choice
        
        case $choice in
            1)
                setup_api_config
                ;;
            2)
                view_balance
                ;;
            3)
                process_single_payout
                ;;
            4)
                process_batch_payouts
                ;;
            5)
                view_payout_history
                ;;
            6)
                view_supported_networks
                ;;
            7)
                test_connection
                ;;
            8)
                echo -e "${GREEN}Thank you for using Bonus Payout Application!${NC}"
                log_info "Application exited by user"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run the application
main "$@" 
