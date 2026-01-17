#!/bin/bash
# Full deployment script for Ubuntu/nginx

set -e

echo "=== Blockchain Matrix Visualizer - Full Deployment ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠ This script must be run as root (use sudo)"
    exit 1
fi

# Configuration
INSTALL_DIR="/var/www/blockchain-matrix-visualizer"
NGINX_SITE="blockchain-matrix-visualizer"

echo "This script will:"
echo "  1. Install system dependencies"
echo "  2. Copy files to $INSTALL_DIR"
echo "  3. Configure nginx"
echo "  4. Set up systemd service"
echo "  5. Start the service"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Install system dependencies
echo ""
echo "=== Installing System Dependencies ==="
apt update
apt install -y python3 python3-pip nginx tor

# Enable and start Tor
echo ""
echo "Starting Tor service..."
systemctl enable tor
systemctl start tor
echo "✓ Tor started"

# Create installation directory
echo ""
echo "=== Setting up Installation Directory ==="
mkdir -p "$INSTALL_DIR"
echo "✓ Created $INSTALL_DIR"

# Copy files (assuming we're in the source directory)
echo ""
echo "Copying files..."
cp -r ./* "$INSTALL_DIR/" || cp -r * "$INSTALL_DIR/"
echo "✓ Files copied"

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
cd "$INSTALL_DIR"
pip3 install -r requirements.txt
echo "✓ Python dependencies installed"

# Create bitcoin_config.json if it doesn't exist
echo ""
echo "Checking configuration..."
if [ ! -f "$INSTALL_DIR/bitcoin_config.json" ]; then
    echo "Creating bitcoin_config.json from example..."
    cp "$INSTALL_DIR/bitcoin_config.example.json" "$INSTALL_DIR/bitcoin_config.json"
    echo "⚠ IMPORTANT: Edit $INSTALL_DIR/bitcoin_config.json with your Bitcoin node credentials"
    echo ""
    read -p "Would you like to edit it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} "$INSTALL_DIR/bitcoin_config.json"
    fi
else
    echo "✓ bitcoin_config.json exists"
fi

# Set permissions
echo ""
echo "Setting permissions..."
chown -R www-data:www-data "$INSTALL_DIR"
chmod 600 "$INSTALL_DIR/bitcoin_config.json"
chmod 755 "$INSTALL_DIR/data"
chmod +x "$INSTALL_DIR"/*.sh
echo "✓ Permissions set"

# Configure nginx
echo ""
echo "=== Configuring Nginx ==="
if [ -f "$INSTALL_DIR/nginx.conf" ]; then
    # Update paths in nginx config
    sed "s|/var/www/blockchain-matrix-visualizer|$INSTALL_DIR|g" "$INSTALL_DIR/nginx.conf" > "/etc/nginx/sites-available/$NGINX_SITE"
    
    # Create symlink if it doesn't exist
    if [ ! -L "/etc/nginx/sites-enabled/$NGINX_SITE" ]; then
        ln -s "/etc/nginx/sites-available/$NGINX_SITE" "/etc/nginx/sites-enabled/$NGINX_SITE"
    fi
    
    echo "✓ Nginx configured"
    
    # Test nginx configuration
    echo "Testing nginx configuration..."
    nginx -t
    
    # Reload nginx
    echo "Reloading nginx..."
    systemctl reload nginx
    echo "✓ Nginx reloaded"
else
    echo "⚠ nginx.conf not found, skipping nginx configuration"
fi

# Install systemd service
echo ""
echo "=== Installing Systemd Service ==="
if [ -f "$INSTALL_DIR/bitcoin-fetcher.service" ]; then
    # Update paths in service file
    sed "s|/var/www/blockchain-matrix-visualizer|$INSTALL_DIR|g" "$INSTALL_DIR/bitcoin-fetcher.service" > "/etc/systemd/system/bitcoin-fetcher.service"
    
    systemctl daemon-reload
    systemctl enable bitcoin-fetcher.service
    systemctl start bitcoin-fetcher.service
    echo "✓ Service installed and started"
else
    echo "⚠ bitcoin-fetcher.service not found, skipping service installation"
fi

# Summary
echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Service Status:"
systemctl status bitcoin-fetcher.service --no-pager || true
echo ""
echo "Next Steps:"
echo "  1. Edit configuration: sudo nano $INSTALL_DIR/bitcoin_config.json"
echo "  2. Restart service: sudo systemctl restart bitcoin-fetcher"
echo "  3. View logs: sudo journalctl -u bitcoin-fetcher -f"
echo "  4. Configure domain in: /etc/nginx/sites-available/$NGINX_SITE"
echo "  5. (Optional) Set up SSL with: sudo certbot --nginx"
echo ""
echo "Access your visualizer at: http://$(hostname -I | awk '{print $1}')"
echo ""
