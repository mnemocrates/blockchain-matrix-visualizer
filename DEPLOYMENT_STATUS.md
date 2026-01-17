# ✅ Ubuntu/Nginx Deployment - Complete

The blockchain-matrix-visualizer has been fully updated for **Ubuntu deployment with nginx**.

## What Changed

### ❌ Removed (Windows-specific)
- ~~setup.ps1~~ (PowerShell script)
- ~~start_fetcher.bat~~ (Windows batch file)

### ✅ Added (Ubuntu/Linux)
- **setup.sh** - Bash setup wizard
- **deploy.sh** - Full automated deployment script
- **install_service.sh** - Systemd service installer
- **start_fetcher.sh** - Manual start script
- **bitcoin-fetcher.service** - Systemd service definition
- **nginx.conf** - Nginx web server configuration

### 📝 Updated Documentation
- **BITCOIN_NODE_SETUP.md** - Rewritten for Ubuntu
- **QUICKSTART.md** - Updated with Linux commands
- **IMPLEMENTATION.md** - Updated for systemd/nginx architecture
- **UBUNTU_DEPLOYMENT.md** - New comprehensive deployment guide
- **SCRIPTS.md** - New script documentation

## Quick Deployment

### Method 1: Fully Automated (Recommended)
```bash
sudo ./deploy.sh
```
This installs everything: nginx, dependencies, systemd service.

### Method 2: Step-by-Step
```bash
# 1. Setup
./setup.sh

# 2. Configure
nano bitcoin_config.json

# 3. Deploy to web directory
sudo cp -r * /var/www/blockchain-matrix-visualizer/
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer/

# 4. Install nginx and service
sudo ./install_service.sh
sudo cp nginx.conf /etc/nginx/sites-available/blockchain-matrix-visualizer
sudo ln -s /etc/nginx/sites-available/blockchain-matrix-visualizer /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Architecture

```
Bitcoin Node (.onion) 
    ↓ (RPC via Tor)
bitcoin_fetcher.py (systemd service)
    ↓ (writes JSON)
/var/www/.../data/current_block.json
    ↓ (serves)
nginx
    ↓ (HTTP/HTTPS)
Browser
```

## Service Management

```bash
# Status
sudo systemctl status bitcoin-fetcher

# Start/Stop/Restart
sudo systemctl start bitcoin-fetcher
sudo systemctl stop bitcoin-fetcher
sudo systemctl restart bitcoin-fetcher

# Logs
sudo journalctl -u bitcoin-fetcher -f

# Enable/Disable auto-start
sudo systemctl enable bitcoin-fetcher
sudo systemctl disable bitcoin-fetcher
```

## File Locations

```
/var/www/blockchain-matrix-visualizer/    # Web root
/etc/nginx/sites-available/               # Nginx config
/etc/systemd/system/                      # Service config
/var/log/nginx/                           # Nginx logs
```

## Key Features

✅ **Runs as systemd service** - Auto-start on boot, auto-restart on failure
✅ **Nginx web server** - Proper static file serving with caching
✅ **Security hardening** - Restricted permissions, unprivileged user
✅ **Tor integration** - Full support for .onion addresses
✅ **Transaction chunking** - Iterative display of block transactions
✅ **SSL/HTTPS ready** - Easy setup with Let's Encrypt/certbot
✅ **Production ready** - Logging, monitoring, error handling

## Security

- Config file permissions: 600 (owner only)
- Service runs as www-data (unprivileged)
- Nginx blocks access to sensitive files
- Systemd security hardening enabled
- bitcoin_config.json never exposed publicly

## Documentation

📖 **Read these guides:**
1. [UBUNTU_DEPLOYMENT.md](UBUNTU_DEPLOYMENT.md) - Complete deployment guide
2. [BITCOIN_NODE_SETUP.md](BITCOIN_NODE_SETUP.md) - Setup instructions
3. [QUICKSTART.md](QUICKSTART.md) - Quick reference
4. [SCRIPTS.md](SCRIPTS.md) - Script documentation

## Testing

```bash
# Test service
sudo systemctl status bitcoin-fetcher

# Test nginx
sudo nginx -t
curl http://localhost/

# Test data file
jq '.block.height' /var/www/blockchain-matrix-visualizer/data/current_block.json

# View logs
sudo journalctl -u bitcoin-fetcher -f
```

## Next Steps

1. ✅ Scripts created for Ubuntu/nginx
2. ✅ Documentation updated
3. ⏭️ Deploy to your Ubuntu server
4. ⏭️ Configure bitcoin_config.json
5. ⏭️ Set up SSL with certbot
6. ⏭️ Access via browser

## Support

If you encounter issues:
1. Check service: `sudo systemctl status bitcoin-fetcher`
2. Check logs: `sudo journalctl -u bitcoin-fetcher -f`
3. Review [UBUNTU_DEPLOYMENT.md](UBUNTU_DEPLOYMENT.md)
4. Test manually: `python3 bitcoin_fetcher.py`

---

**Status:** ✅ Ready for Ubuntu/nginx deployment
**Platform:** Ubuntu 20.04+ with nginx
**Python:** 3.7+
**Service:** systemd
**Web Server:** nginx
