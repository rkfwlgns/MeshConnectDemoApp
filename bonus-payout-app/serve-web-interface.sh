#!/opt/homebrew/bin/bash

# Serve Web Interface for MeshConnect Link UI Testing
# This script starts a simple HTTP server to serve the web interface

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    MeshConnect Web Interface Server${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if web-interface.html exists
if [[ ! -f "$SCRIPT_DIR/web-interface.html" ]]; then
    echo -e "${RED}Error: web-interface.html not found${NC}"
    exit 1
fi

# Find an available port
PORT=3000
while lsof -i:$PORT >/dev/null 2>&1; do
    ((PORT++))
done

echo -e "${GREEN}Starting web server...${NC}"
echo -e "Port: ${YELLOW}$PORT${NC}"
echo -e "URL: ${YELLOW}http://localhost:$PORT${NC}"
echo ""
echo -e "${BLUE}Instructions:${NC}"
echo "1. Keep this terminal window open"
echo "2. Open your browser to http://localhost:$PORT"
echo "3. Run ./bonus-payout.sh in another terminal"
echo "4. Copy the link token and paste it in the web interface"
echo "5. Click 'Process Payment' to use MeshConnect Link UI"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Start the server
if command -v python3 &> /dev/null; then
    cd "$SCRIPT_DIR"
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    cd "$SCRIPT_DIR"
    python -m SimpleHTTPServer $PORT
else
    echo -e "${RED}Error: Python not found. Please install Python to run the web server.${NC}"
    echo "Alternative: Open web-interface.html directly in your browser"
    exit 1
fi 