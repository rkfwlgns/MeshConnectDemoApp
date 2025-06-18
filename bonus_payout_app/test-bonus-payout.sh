#!/opt/homebrew/bin/bash

# Test Integration Script - Generates a test bonus payout automatically
# This demonstrates the complete flow without manual input

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
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}      Integration Test - Bonus Payout${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check configuration
if ! check_config; then
    echo -e "${RED}Please run './bonus-payout.sh' and select option 1 to configure API credentials first.${NC}"
    exit 1
fi

echo -e "${YELLOW}🧪 Creating test bonus payout...${NC}"
echo ""

# Test payout data
TEST_EMAIL="test.employee@company.com"
TEST_ADDRESS="0x742d35Cc6634C0532925a3b8D66C2dDc168E7d8f"
TEST_AMOUNT="100.00"
TEST_SYMBOL="USDC"
TEST_NETWORK="Ethereum"
TEST_DESCRIPTION="Q4 Performance Bonus - Integration Test"

echo "Test Payout Details:"
echo "• Recipient: $TEST_EMAIL"
echo "• Wallet: $TEST_ADDRESS"
echo "• Amount: $TEST_AMOUNT $TEST_SYMBOL"
echo "• Network: $TEST_NETWORK"
echo "• Description: $TEST_DESCRIPTION"
echo ""

# Validate test inputs
echo -e "${YELLOW}🔍 Validating test data...${NC}"
if validate_payout_inputs "$TEST_EMAIL" "$TEST_ADDRESS" "$TEST_AMOUNT" "$TEST_SYMBOL"; then
    echo -e "${GREEN}✓ Test data validation passed${NC}"
else
    echo -e "${RED}✗ Test data validation failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🚀 Processing test payout...${NC}"

# Process the test payout
if process_payout "$TEST_EMAIL" "$TEST_ADDRESS" "$TEST_AMOUNT" "$TEST_SYMBOL" "$TEST_NETWORK" "$TEST_DESCRIPTION"; then
    echo ""
    echo -e "${GREEN}✅ Test payout created successfully!${NC}"
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}             NEXT STEPS${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "1. 📋 Copy the link token from above"
    echo "2. 🌐 Open a new terminal and run: ./serve-web-interface.sh"
    echo "3. 🔗 Open your browser to the URL shown"
    echo "4. 📝 Paste the link token in the web interface"
    echo "5. 💳 Click 'Process Payment' to connect to Coinbase"
    echo "6. 🏦 Complete the Coinbase OAuth flow"
    echo "7. ✅ Execute the test bonus payment"
    echo ""
    echo -e "${GREEN}🎉 Integration test ready!${NC}"
else
    echo ""
    echo -e "${RED}✗ Test payout creation failed${NC}"
    echo "Check the error messages above and verify your API configuration."
    exit 1
fi 