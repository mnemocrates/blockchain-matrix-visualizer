#!/bin/bash
# Install Bitcoin Fetcher as a systemd service

set -e

echo "=== Installing Bitcoin Fetcher Service ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠ This script must be run as root (use sudo)"
    exit 1
fi

# Get the current directory
INSTALL_DIR=$(pwd)
echo "Installation directory: $INSTALL_DIR"

# Copy service file to systemd directory
echo ""
echo "Installing systemd service..."
cp bitcoin-fetcher.service /etc/systemd/system/
echo "✓ Service file copied"

# Update WorkingDirectory and ExecStart paths in service file
echo "Updating service file paths..."
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$INSTALL_DIR|g" /etc/systemd/system/bitcoin-fetcher.service
sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $INSTALL_DIR/bitcoin_fetcher.py|g" /etc/systemd/system/bitcoin-fetcher.service

# Update ReadWritePaths
sed -i "s|ReadWritePaths=.*|ReadWritePaths=$INSTALL_DIR/data|g" /etc/systemd/system/bitcoin-fetcher.service
echo "✓ Paths updated"

# Set proper ownership (assuming www-data user for nginx)
echo ""
echo "Setting file ownership..."
chown -R www-data:www-data "$INSTALL_DIR"
chmod 600 "$INSTALL_DIR/bitcoin_config.json"
chmod 755 "$INSTALL_DIR/data"
echo "✓ Ownership set to www-data:www-data"

# Reload systemd
echo ""
echo "Reloading systemd..."
systemctl daemon-reload
echo "✓ Systemd reloaded"

# Enable service to start on boot
echo ""
echo "Enabling service..."
systemctl enable bitcoin-fetcher.service
echo "✓ Service enabled"

# Start service
echo ""
echo "Starting service..."
systemctl start bitcoin-fetcher.service
echo "✓ Service started"

# Show status
echo ""
echo "Service status:"
systemctl status bitcoin-fetcher.service --no-pager

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Useful commands:"
echo "  Check status:  sudo systemctl status bitcoin-fetcher"
echo "  View logs:     sudo journalctl -u bitcoin-fetcher -f"
echo "  Restart:       sudo systemctl restart bitcoin-fetcher"
echo "  Stop:          sudo systemctl stop bitcoin-fetcher"
echo "  Disable:       sudo systemctl disable bitcoin-fetcher"
echo ""
