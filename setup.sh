#!/bin/bash
# Bitcoin Node Setup Script for Blockchain Matrix Visualizer (Ubuntu/Linux)
# This script helps you set up the local Bitcoin node integration

set -e

echo "=== Bitcoin Matrix Visualizer - Node Setup ==="
echo ""

# Check if Python is installed
echo "Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ $PYTHON_VERSION"
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo "✓ $PYTHON_VERSION"
    PYTHON_CMD="python"
else
    echo "✗ Python not found. Please install Python 3.7+ first."
    echo "  Ubuntu: sudo apt install python3 python3-pip"
    exit 1
fi

# Check if pip is installed
echo ""
echo "Checking pip installation..."
if command -v pip3 &> /dev/null; then
    echo "✓ pip3 found"
    PIP_CMD="pip3"
elif command -v pip &> /dev/null; then
    echo "✓ pip found"
    PIP_CMD="pip"
else
    echo "✗ pip not found. Installing..."
    sudo apt update
    sudo apt install -y python3-pip
    PIP_CMD="pip3"
fi

# Check if bitcoin_config.json exists
echo ""
echo "Checking configuration..."
if [ ! -f "bitcoin_config.json" ]; then
    echo "✗ bitcoin_config.json not found"
    echo "Creating from example..."
    cp bitcoin_config.example.json bitcoin_config.json
    echo "✓ Created bitcoin_config.json"
    echo ""
    echo "⚠ IMPORTANT: Edit bitcoin_config.json with your Bitcoin node credentials!"
    echo "  - rpc_url: Your Bitcoin node address (.onion or local)"
    echo "  - rpc_user: Your RPC username"
    echo "  - rpc_password: Your RPC password"
    echo ""
    
    # Ask if user wants to edit now
    read -p "Would you like to edit bitcoin_config.json now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} bitcoin_config.json
    fi
else
    echo "✓ bitcoin_config.json exists"
fi

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
$PIP_CMD install -r requirements.txt --quiet
echo "✓ Dependencies installed"

# Check if Tor is running
echo ""
echo "Checking Tor status..."
if pgrep -x "tor" > /dev/null; then
    TOR_PID=$(pgrep -x "tor")
    echo "✓ Tor is running (PID: $TOR_PID)"
else
    echo "⚠ Tor not detected"
    echo "  If your node is .onion-only, ensure Tor is running"
    echo "  Ubuntu: sudo apt install tor && sudo systemctl start tor"
fi

# Create data directory if it doesn't exist
echo ""
echo "Checking data directory..."
if [ ! -d "data" ]; then
    mkdir -p data
    echo "✓ Created data directory"
else
    echo "✓ Data directory exists"
fi

# Set proper permissions
echo ""
echo "Setting permissions..."
chmod +x bitcoin_fetcher.py 2>/dev/null || true
chmod 600 bitcoin_config.json 2>/dev/null || true
echo "✓ Permissions set"

# Summary
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Ensure bitcoin_config.json has your correct node credentials"
echo "2. Start the fetcher service:"
echo "   For testing: ./start_fetcher.sh"
echo "   For production: sudo ./install_service.sh"
echo "3. Configure nginx (see BITCOIN_NODE_SETUP.md)"
echo "4. Open your site in a browser"
echo ""
echo "For detailed instructions, see: BITCOIN_NODE_SETUP.md"
echo ""

# Ask if user wants to start the fetcher now
read -p "Would you like to start the Bitcoin fetcher now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting bitcoin_fetcher.py..."
    echo "Press Ctrl+C to stop"
    echo ""
    $PYTHON_CMD bitcoin_fetcher.py
fi
