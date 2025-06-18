#!/opt/homebrew/bin/bash

# Debug script for MeshConnect API issues
# Enables debug mode and tests API connectivity with verbose output

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

# Enable debug mode
export DEBUG=true

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}         MeshConnect API Debug Tool${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check configuration
echo -e "${YELLOW}1. Checking Configuration...${NC}"
show_config_status
echo ""

if ! check_config; then
    echo -e "${RED}Configuration is incomplete. Please run './bonus-payout.sh' and select option 1 to configure API credentials.${NC}"
    exit 1
fi

# Check dependencies
echo -e "${YELLOW}2. Checking Dependencies...${NC}"
check_dependencies
echo ""

# Test basic curl connectivity
echo -e "${YELLOW}3. Testing Basic Connectivity...${NC}"
load_config
BASE_URL=$(get_api_base_url)
echo "Testing connectivity to: $BASE_URL"

if curl -s --connect-timeout 10 "$BASE_URL" >/dev/null; then
    echo -e "${GREEN}✓ Basic connectivity successful${NC}"
else
    echo -e "${RED}✗ Basic connectivity failed${NC}"
    echo "Please check your internet connection and firewall settings."
    exit 1
fi
echo ""

# Test API authentication
echo -e "${YELLOW}4. Testing API Authentication...${NC}"
echo "Attempting to create a simple link token..."

# Create proper test payload according to MeshConnect docs
TEST_PAYLOAD='{
    "userId": "debug_test_'"$(date +%s)"'",
    "restrictMultipleAccounts": false
}'

echo "Test payload: $TEST_PAYLOAD"
echo ""

# Make the API request with debug output
echo "Making API request..."
RESPONSE=$(api_request "POST" "/api/v1/linktoken" "$TEST_PAYLOAD")
API_EXIT_CODE=$?

echo ""
echo -e "${YELLOW}5. API Response Analysis...${NC}"

if [[ $API_EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ API request completed successfully${NC}"
    
    if command -v jq &> /dev/null; then
        echo ""
        echo "Formatted response:"
        echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
        
        # Check for link token
        LINK_TOKEN=$(echo "$RESPONSE" | jq -r '.content.linkToken // empty')
        if [[ -n "$LINK_TOKEN" ]]; then
            echo ""
            echo -e "${GREEN}✓ Link token extracted successfully${NC}"
            echo "Link token (first 50 chars): ${LINK_TOKEN:0:50}..."
        else
            echo ""
            echo -e "${YELLOW}⚠ No link token found in response${NC}"
            
            # Check for error messages
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // empty')
            ERROR_TYPE=$(echo "$RESPONSE" | jq -r '.errorType // empty')
            STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
            
            if [[ -n "$ERROR_MSG" ]]; then
                echo "Error message: $ERROR_MSG"
            fi
            if [[ -n "$ERROR_TYPE" ]]; then
                echo "Error type: $ERROR_TYPE"
            fi
            if [[ -n "$STATUS" ]]; then
                echo "Status: $STATUS"
            fi
        fi
    else
        echo "Raw response (jq not available):"
        echo "$RESPONSE"
    fi
else
    echo -e "${RED}✗ API request failed${NC}"
    echo "Response: $RESPONSE"
fi

echo ""
echo -e "${YELLOW}6. Summary and Recommendations...${NC}"

if [[ $API_EXIT_CODE -eq 0 ]]; then
    LINK_TOKEN=$(echo "$RESPONSE" | jq -r '.content.linkToken // empty' 2>/dev/null)
    if [[ -n "$LINK_TOKEN" ]]; then
        echo -e "${GREEN}✓ Everything looks good! Your API configuration is working correctly.${NC}"
        echo ""
        echo "You can now:"
        echo "1. Run './bonus-payout.sh' to process payouts"
        echo "2. Use the generated link tokens with the web interface"
    else
        echo -e "${YELLOW}⚠ API is responding but not returning link tokens.${NC}"
        echo ""
        echo "Possible causes:"
        echo "1. API credentials might be for a different environment"
        echo "2. Account might not be properly set up"
        echo "3. Missing required parameters in the request"
        echo ""
        echo "Next steps:"
        echo "1. Verify your API credentials in the MeshConnect dashboard"
        echo "2. Ensure you're using the correct environment (sandbox/production)"
        echo "3. Contact MeshConnect support if the issue persists"
    fi
else
    echo -e "${RED}✗ API connection is failing.${NC}"
    echo ""
    echo "Possible causes:"
    echo "1. Invalid API credentials"
    echo "2. Network connectivity issues"
    echo "3. Incorrect API endpoint"
    echo "4. API service is down"
    echo ""
    echo "Next steps:"
    echo "1. Double-check your API key and secret"
    echo "2. Verify you're using the correct environment"
    echo "3. Try again in a few minutes"
    echo "4. Contact MeshConnect support if the issue persists"
fi

echo ""
echo -e "${BLUE}Debug session complete.${NC}"

# Disable debug mode
export DEBUG=false 