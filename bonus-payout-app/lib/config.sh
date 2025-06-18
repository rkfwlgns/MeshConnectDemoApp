#!/opt/homebrew/bin/bash

# Configuration management for Bonus Payout Application
# Handles API keys, environment settings, and configuration validation

CONFIG_FILE="$SCRIPT_DIR/.env"
CONFIG_DIR="$SCRIPT_DIR/data"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Default MeshConnect API endpoints
MESH_SANDBOX_BASE_URL="https://sandbox-integration-api.meshconnect.com"
MESH_PRODUCTION_BASE_URL="https://integration-api.meshconnect.com"

# Load configuration from file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# Save configuration to file
save_config() {
    local key="$1"
    local value="$2"
    
    # Create config file if it doesn't exist
    touch "$CONFIG_FILE"
    
    # Remove existing key if present
    grep -v "^${key}=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
    
    # Add new key-value pair
    echo "${key}=${value}" >> "$CONFIG_FILE.tmp"
    
    # Move temp file to config file
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    # Set secure permissions
    chmod 600 "$CONFIG_FILE"
}

# Check if configuration is complete
check_config() {
    load_config
    
    if [[ -z "$MESH_API_KEY" ]] || [[ -z "$MESH_API_SECRET" ]] || [[ -z "$MESH_ENV" ]]; then
        echo -e "${RED}Configuration incomplete. Please run 'Setup API Configuration' first.${NC}"
        return 1
    fi
    
    return 0
}

# Get API base URL based on environment
get_api_base_url() {
    load_config
    
    if [[ "$MESH_ENV" == "production" ]]; then
        echo "$MESH_PRODUCTION_BASE_URL"
    else
        echo "$MESH_SANDBOX_BASE_URL"
    fi
}

# Generate authentication headers for MeshConnect
get_auth_headers() {
    load_config
    
    if [[ -z "$MESH_API_KEY" ]] || [[ -z "$MESH_API_SECRET" ]]; then
        return 1
    fi
    
    # MeshConnect uses X-Client-Id and X-Client-Secret headers
    echo "X-Client-Id: ${MESH_API_KEY}"
    echo "X-Client-Secret: ${MESH_API_SECRET}"
}

# Validate API credentials format
validate_credentials() {
    local api_key="$1"
    local api_secret="$2"
    
    if [[ ${#api_key} -lt 10 ]]; then
        echo -e "${RED}API key appears to be too short${NC}"
        return 1
    fi
    
    if [[ ${#api_secret} -lt 10 ]]; then
        echo -e "${RED}API secret appears to be too short${NC}"
        return 1
    fi
    
    return 0
}

# Initialize configuration
init_config() {
    # Load existing configuration if available
    load_config
    
    # Set default values if not set
    if [[ -z "$MESH_ENV" ]]; then
        export MESH_ENV="sandbox"
    fi
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/lib"
}

# Display current configuration status
show_config_status() {
    load_config
    
    echo -e "${BLUE}Current Configuration:${NC}"
    echo "Environment: ${MESH_ENV:-'Not set'}"
    echo "API Key: ${MESH_API_KEY:+Set (hidden)}${MESH_API_KEY:-'Not set'}"
    echo "API Secret: ${MESH_API_SECRET:+Set (hidden)}${MESH_API_SECRET:-'Not set'}"
    echo "Base URL: $(get_api_base_url)"
}

# Export configuration variables
export_config() {
    load_config
    
    export MESH_API_KEY
    export MESH_API_SECRET
    export MESH_ENV
    export MESH_BASE_URL=$(get_api_base_url)
}

# Initialize configuration on load
init_config 