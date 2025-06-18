#!/bin/bash

# Setup script for Bonus Payout Application
# Handles initial installation, dependency checking, and environment setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Bonus Payout Application Setup${NC}"
echo -e "${BLUE}    Powered by MeshConnect${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if running on macOS or Linux
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}✓ Detected macOS${NC}"
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${GREEN}✓ Detected Linux${NC}"
        OS="linux"
    else
        echo -e "${RED}✗ Unsupported operating system: $OSTYPE${NC}"
        echo "This application requires macOS or Linux."
        exit 1
    fi
}

# Check Bash version
check_bash_version() {
    local bash_version=${BASH_VERSION%%.*}
    if [[ $bash_version -ge 4 ]]; then
        echo -e "${GREEN}✓ Bash version $BASH_VERSION is supported${NC}"
    else
        echo -e "${RED}✗ Bash version $BASH_VERSION is not supported${NC}"
        echo "Please upgrade to Bash 4.0 or higher."
        exit 1
    fi
}

# Check for required commands
check_dependencies() {
    echo ""
    echo "Checking dependencies..."
    
    # Check for curl
    if command -v curl &> /dev/null; then
        echo -e "${GREEN}✓ curl is available${NC}"
    else
        echo -e "${RED}✗ curl is not installed${NC}"
        if [[ "$OS" == "macos" ]]; then
            echo "Install with: brew install curl"
        else
            echo "Install with: sudo apt-get install curl (Ubuntu/Debian) or sudo yum install curl (CentOS/RHEL)"
        fi
        exit 1
    fi
    
    # Check for jq (optional but recommended)
    if command -v jq &> /dev/null; then
        echo -e "${GREEN}✓ jq is available${NC}"
    else
        echo -e "${YELLOW}⚠ jq is not installed (recommended for better JSON parsing)${NC}"
        if [[ "$OS" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                echo "Would you like to install jq via Homebrew? (y/N)"
                read -r install_jq
                if [[ "$install_jq" =~ ^[Yy]$ ]]; then
                    echo "Installing jq..."
                    brew install jq
                    if [[ $? -eq 0 ]]; then
                        echo -e "${GREEN}✓ jq installed successfully${NC}"
                    else
                        echo -e "${YELLOW}⚠ Failed to install jq, but the application will still work${NC}"
                    fi
                fi
            else
                echo "Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                echo "Then install jq: brew install jq"
            fi
        else
            echo "Install with: sudo apt-get install jq (Ubuntu/Debian) or sudo yum install jq (CentOS/RHEL)"
        fi
    fi
    
    # Check for bc (basic calculator - for numeric operations)
    if command -v bc &> /dev/null; then
        echo -e "${GREEN}✓ bc is available${NC}"
    else
        echo -e "${YELLOW}⚠ bc is not installed (recommended for numeric calculations)${NC}"
        if [[ "$OS" == "macos" ]]; then
            echo "Install with: brew install bc"
        else
            echo "Install with: sudo apt-get install bc (Ubuntu/Debian) or sudo yum install bc (CentOS/RHEL)"
        fi
    fi
}

# Create directory structure
create_directories() {
    echo ""
    echo "Creating directory structure..."
    
    local dirs=("lib" "logs" "data" "tmp" "backups")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
            mkdir -p "$SCRIPT_DIR/$dir"
            echo -e "${GREEN}✓ Created directory: $dir${NC}"
        else
            echo -e "${BLUE}• Directory exists: $dir${NC}"
        fi
    done
}

# Set file permissions
set_permissions() {
    echo ""
    echo "Setting file permissions..."
    
    # Make main script executable
    chmod +x "$SCRIPT_DIR/bonus-payout.sh"
    echo -e "${GREEN}✓ Made bonus-payout.sh executable${NC}"
    
    # Make setup script executable
    chmod +x "$SCRIPT_DIR/setup.sh"
    echo -e "${GREEN}✓ Made setup.sh executable${NC}"
    
    # Set secure permissions for lib directory
    chmod 755 "$SCRIPT_DIR/lib"
    if [[ -f "$SCRIPT_DIR/lib/config.sh" ]]; then
        chmod 644 "$SCRIPT_DIR/lib/"*.sh
    fi
    
    # Set secure permissions for logs directory
    chmod 750 "$SCRIPT_DIR/logs"
    
    # Set secure permissions for data directory
    chmod 750 "$SCRIPT_DIR/data"
    
    echo -e "${GREEN}✓ File permissions set${NC}"
}

# Create .env file with proper permissions
create_env_file() {
    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
        touch "$SCRIPT_DIR/.env"
        chmod 600 "$SCRIPT_DIR/.env"
        echo -e "${GREEN}✓ Created .env file with secure permissions${NC}"
    else
        echo -e "${BLUE}• .env file already exists${NC}"
        chmod 600 "$SCRIPT_DIR/.env"
        echo -e "${GREEN}✓ Updated .env file permissions${NC}"
    fi
}

# Check if library files exist
check_library_files() {
    echo ""
    echo "Checking library files..."
    
    local lib_files=("config.sh" "api.sh" "utils.sh" "logging.sh")
    local missing_files=()
    
    for file in "${lib_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/lib/$file" ]]; then
            echo -e "${GREEN}✓ Found lib/$file${NC}"
        else
            echo -e "${RED}✗ Missing lib/$file${NC}"
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${RED}Missing library files. Please ensure all files are present.${NC}"
        return 1
    fi
    
    return 0
}

# Test basic functionality
test_basic_functionality() {
    echo ""
    echo "Testing basic functionality..."
    
    # Source the library files to test if they load correctly
    if source "$SCRIPT_DIR/lib/config.sh" 2>/dev/null; then
        echo -e "${GREEN}✓ config.sh loads correctly${NC}"
    else
        echo -e "${RED}✗ config.sh has syntax errors${NC}"
        return 1
    fi
    
    if source "$SCRIPT_DIR/lib/utils.sh" 2>/dev/null; then
        echo -e "${GREEN}✓ utils.sh loads correctly${NC}"
    else
        echo -e "${RED}✗ utils.sh has syntax errors${NC}"
        return 1
    fi
    
    if source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null; then
        echo -e "${GREEN}✓ logging.sh loads correctly${NC}"
    else
        echo -e "${RED}✗ logging.sh has syntax errors${NC}"
        return 1
    fi
    
    if source "$SCRIPT_DIR/lib/api.sh" 2>/dev/null; then
        echo -e "${GREEN}✓ api.sh loads correctly${NC}"
    else
        echo -e "${RED}✗ api.sh has syntax errors${NC}"
        return 1
    fi
    
    return 0
}

# Display next steps
show_next_steps() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the application: ./bonus-payout.sh"
    echo "2. Choose option 1 to configure your MeshConnect API credentials"
    echo "3. Test the connection with option 6"
    echo "4. Start processing bonus payouts!"
    echo ""
    echo "Documentation:"
    echo "- README.md - Complete usage guide"
    echo "- sample_payouts.csv - Example CSV format for batch processing"
    echo ""
    echo "Need help?"
    echo "- Check the logs in the logs/ directory"
    echo "- Review the README.md file"
    echo "- Contact MeshConnect support for API issues"
    echo ""
}

# Main setup function
main() {
    check_os
    check_bash_version
    check_dependencies
    create_directories
    set_permissions
    create_env_file
    
    if check_library_files && test_basic_functionality; then
        show_next_steps
        return 0
    else
        echo ""
        echo -e "${RED}Setup completed with errors. Please check the output above.${NC}"
        return 1
    fi
}

# Run setup
main "$@" 