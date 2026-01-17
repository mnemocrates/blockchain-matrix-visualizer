# Deployment Scripts

This directory contains scripts for deploying the blockchain-matrix-visualizer on Ubuntu with nginx.

## Scripts Overview

### setup.sh
**Purpose:** Interactive setup wizard for initial configuration
**Usage:** `./setup.sh`
**What it does:**
- Checks for Python 3 and pip
- Creates `bitcoin_config.json` from example
- Installs Python dependencies
- Checks Tor status
- Creates data directory
- Sets file permissions
- Offers to start the fetcher

**When to use:** First-time setup, development environment

---

### deploy.sh  
**Purpose:** Complete automated deployment (production)
**Usage:** `sudo ./deploy.sh`
**What it does:**
- Installs system dependencies (nginx, Python, Tor)
- Copies files to `/var/www/blockchain-matrix-visualizer`
- Configures nginx
- Sets up systemd service
- Sets proper ownership and permissions
- Starts the service

**When to use:** Fresh production deployment, automated CI/CD

**Requires:** Root privileges (sudo)

---

### install_service.sh
**Purpose:** Install bitcoin-fetcher as systemd service
**Usage:** `sudo ./install_service.sh`
**What it does:**
- Copies service file to `/etc/systemd/system/`
- Updates paths in service file
- Sets ownership to www-data
- Enables and starts the service

**When to use:** After manual file placement, service updates

**Requires:** Root privileges (sudo)

---

### start_fetcher.sh
**Purpose:** Manually run the fetcher (development/testing)
**Usage:** `./start_fetcher.sh`
**What it does:**
- Runs `bitcoin_fetcher.py` in the foreground
- Uses python3 or python (whichever is available)

**When to use:** Testing, development, debugging

**Note:** Stops when you press Ctrl+C

---

## Quick Start Workflows

### Development Setup
```bash
# 1. Run setup wizard
./setup.sh

# 2. Edit configuration with your credentials
nano bitcoin_config.json

# 3. Test the fetcher
./start_fetcher.sh

# 4. When working, press Ctrl+C and install as service
sudo ./install_service.sh
```

### Production Deployment
```bash
# One command deployment
sudo ./deploy.sh

# Then edit configuration
sudo nano /var/www/blockchain-matrix-visualizer/bitcoin_config.json

# Restart service with new config
sudo systemctl restart bitcoin-fetcher
```

### Service Update
```bash
# After modifying bitcoin_fetcher.py or service file
sudo ./install_service.sh
```

## File Permissions

All scripts should be executable:
```bash
chmod +x setup.sh
chmod +x deploy.sh  
chmod +x install_service.sh
chmod +x start_fetcher.sh
```

If deploying to `/var/www/`, ensure correct ownership:
```bash
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer
sudo chmod +x /var/www/blockchain-matrix-visualizer/*.sh
```

## Configuration Files

### bitcoin-fetcher.service
Systemd service definition that:
- Runs bitcoin_fetcher.py as www-data user
- Auto-restarts on failure
- Logs to journald
- Starts on boot

**Location after install:** `/etc/systemd/system/bitcoin-fetcher.service`

### nginx.conf
Nginx site configuration that:
- Serves static files
- Serves JSON with no-cache headers
- Protects sensitive files
- Adds security headers
- Optional SSL support

**Location after install:** `/etc/nginx/sites-available/blockchain-matrix-visualizer`

## Troubleshooting Scripts

### setup.sh fails
```bash
# Check Python installation
python3 --version

# Install Python if missing
sudo apt install python3 python3-pip

# Check permissions
ls -la setup.sh
chmod +x setup.sh
```

### deploy.sh fails
```bash
# Ensure running as root
sudo ./deploy.sh

# Check disk space
df -h

# Check nginx package
sudo apt install nginx

# View script output carefully for specific errors
```

### install_service.sh fails
```bash
# Check if service file exists
ls -la bitcoin-fetcher.service

# Check systemd syntax
systemd-analyze verify bitcoin-fetcher.service

# View systemd errors
sudo journalctl -xe
```

### start_fetcher.sh fails
```bash
# Check Python installation
which python3

# Check dependencies
pip3 list | grep requests

# Test manually
python3 bitcoin_fetcher.py

# Check config file
cat bitcoin_config.json | python3 -m json.tool
```

## Environment Variables

Scripts respect these environment variables:

### EDITOR
Used by setup.sh for editing config files
```bash
export EDITOR=vim
./setup.sh
```

### PYTHON_CMD
Override Python command (default: python3)
```bash
export PYTHON_CMD=python3.11
./start_fetcher.sh
```

## Script Exit Codes

All scripts follow standard exit codes:
- `0` - Success
- `1` - General error
- `2` - Misuse (wrong arguments)

Check exit code:
```bash
./setup.sh
echo $?  # 0 = success, non-zero = error
```

## Logs and Output

### Service logs
```bash
sudo journalctl -u bitcoin-fetcher -f
```

### Nginx logs
```bash
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.access.log
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log
```

### Script output
All scripts use standard output (stdout) and standard error (stderr).
Redirect if needed:
```bash
./setup.sh > setup.log 2>&1
```

## Security Notes

- `bitcoin_config.json` contains sensitive credentials
- Always use proper file permissions (600 for config)
- Run service as www-data user (unprivileged)
- Never commit `bitcoin_config.json` to version control
- Use strong RPC passwords
- Enable firewall (ufw) in production
- Use HTTPS in production (certbot)

## Advanced Usage

### Unattended Installation
```bash
# Skip interactive prompts
yes n | ./setup.sh

# Or with heredoc
./setup.sh <<EOF
n
n
EOF
```

### Custom Install Directory
Edit `deploy.sh` and change:
```bash
INSTALL_DIR="/your/custom/path"
```

### Service as Different User
Edit `bitcoin-fetcher.service`:
```ini
User=youruser
Group=yourgroup
```

## Maintenance

### Update Scripts
```bash
# Pull latest from git
git pull origin main

# Or manually download updated scripts
```

### Reinstall Service
```bash
# Stop existing service
sudo systemctl stop bitcoin-fetcher

# Update files
sudo ./install_service.sh

# Service is automatically restarted
```

### Clean Reinstall
```bash
# Stop service
sudo systemctl stop bitcoin-fetcher
sudo systemctl disable bitcoin-fetcher

# Remove service file
sudo rm /etc/systemd/system/bitcoin-fetcher.service
sudo systemctl daemon-reload

# Remove nginx config
sudo rm /etc/nginx/sites-enabled/blockchain-matrix-visualizer
sudo rm /etc/nginx/sites-available/blockchain-matrix-visualizer
sudo systemctl reload nginx

# Remove installation
sudo rm -rf /var/www/blockchain-matrix-visualizer

# Start fresh
sudo ./deploy.sh
```

## Support

For detailed documentation:
- [BITCOIN_NODE_SETUP.md](BITCOIN_NODE_SETUP.md) - Complete setup guide
- [QUICKSTART.md](QUICKSTART.md) - Quick reference
- [UBUNTU_DEPLOYMENT.md](UBUNTU_DEPLOYMENT.md) - Ubuntu-specific deployment
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Technical details
