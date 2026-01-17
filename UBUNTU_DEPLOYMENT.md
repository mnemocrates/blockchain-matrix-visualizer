# Ubuntu/Nginx Deployment Summary

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Bitcoin Core Node                         │
│                  (Tor .onion address)                        │
└───────────────────────────┬─────────────────────────────────┘
                            │ RPC over Tor (port 8332)
                            │
┌───────────────────────────▼─────────────────────────────────┐
│           bitcoin_fetcher.py (systemd service)               │
│           - Runs as www-data user                            │
│           - Polls for new blocks every 30s                   │
│           - Processes transactions in chunks                 │
└───────────────────────────┬─────────────────────────────────┘
                            │ Writes JSON
                            ▼
┌───────────────────────────────────────────────────────────┐
│             /var/www/.../data/current_block.json            │
└───────────────────────────┬─────────────────────────────────┘
                            │ Reads
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    nginx Web Server                          │
│           - Serves static files (HTML/JS/CSS)                │
│           - Serves JSON with no-cache headers                │
│           - Protects sensitive files                         │
│           - Optional SSL/HTTPS                               │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP(S)
                            ▼
                      ┌───────────┐
                      │  Browser  │
                      │  (Users)  │
                      └───────────┘
```

## File Structure

```
/var/www/blockchain-matrix-visualizer/
├── bitcoin_fetcher.py              # Backend service ⭐
├── bitcoin_config.json             # Private config (create from example)
├── bitcoin_config.example.json     # Template
├── bitcoin-fetcher.service         # Systemd service definition ⭐
├── nginx.conf                      # Nginx configuration ⭐
├── setup.sh                        # Setup wizard ⭐
├── deploy.sh                       # Full deployment script ⭐
├── install_service.sh             # Service installer ⭐
├── start_fetcher.sh               # Manual start script ⭐
├── requirements.txt               # Python dependencies
├── config.json                    # Frontend configuration
├── index.html                     # Visualizer frontend
├── data/                          # Block data directory
│   ├── current_block.json         # Current block (served by nginx)
│   └── block_*.json               # Historical blocks
├── status/                        # Optional status monitoring
│   └── status.json
└── .gitignore                     # Protects sensitive files

⭐ = New/Updated for Ubuntu deployment
```

## System Configuration

### Nginx Configuration
**Location:** `/etc/nginx/sites-available/blockchain-matrix-visualizer`
**Enabled:** `/etc/nginx/sites-enabled/blockchain-matrix-visualizer` (symlink)

Key features:
- Serves static files with caching
- JSON files never cached (always fresh)
- Blocks access to bitcoin_config.json and .git
- Security headers enabled
- Ready for SSL/HTTPS with Let's Encrypt

### Systemd Service
**Location:** `/etc/systemd/system/bitcoin-fetcher.service`

Key features:
- Runs as www-data user (nginx compatibility)
- Auto-restart on failure
- Logs to journald
- Security hardening enabled
- Starts on boot

### File Permissions
```
/var/www/blockchain-matrix-visualizer/
- Owner: www-data:www-data
- bitcoin_config.json: 600 (read/write owner only)
- data/: 755 (read/execute all, write owner)
- *.sh: 755 (executable)
```

## Deployment Options

### Option 1: Fully Automated (Recommended)
```bash
sudo ./deploy.sh
```
Installs everything: dependencies, nginx, systemd service, starts service.

### Option 2: Step-by-Step
```bash
# 1. Run setup
./setup.sh

# 2. Edit configuration
nano bitcoin_config.json

# 3. Move to web directory
sudo cp -r * /var/www/blockchain-matrix-visualizer/
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer/

# 4. Configure nginx
sudo cp nginx.conf /etc/nginx/sites-available/blockchain-matrix-visualizer
sudo ln -s /etc/nginx/sites-available/blockchain-matrix-visualizer /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 5. Install service
cd /var/www/blockchain-matrix-visualizer
sudo ./install_service.sh
```

### Option 3: Development Mode (No Service)
```bash
# Run setup
./setup.sh

# Edit config
nano bitcoin_config.json

# Run manually (stays in foreground)
./start_fetcher.sh
```

## Service Commands

```bash
# Status
sudo systemctl status bitcoin-fetcher

# Start/Stop/Restart
sudo systemctl start bitcoin-fetcher
sudo systemctl stop bitcoin-fetcher
sudo systemctl restart bitcoin-fetcher

# Logs
sudo journalctl -u bitcoin-fetcher -f       # Follow logs
sudo journalctl -u bitcoin-fetcher -n 50    # Last 50 lines
sudo journalctl -u bitcoin-fetcher -p err   # Errors only

# Enable/Disable auto-start
sudo systemctl enable bitcoin-fetcher
sudo systemctl disable bitcoin-fetcher
```

## Nginx Commands

```bash
# Test configuration
sudo nginx -t

# Reload (graceful)
sudo systemctl reload nginx

# Restart (stops then starts)
sudo systemctl restart nginx

# View logs
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.access.log
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log
```

## Security Features

### 1. Private Configuration
- `bitcoin_config.json` has 600 permissions (owner read/write only)
- Added to `.gitignore` to prevent commits
- Never served by nginx (explicitly blocked)

### 2. Systemd Security
- `NoNewPrivileges=true` - Cannot gain new privileges
- `PrivateTmp=true` - Private /tmp directory
- `ProtectSystem=strict` - Read-only system directories
- `ProtectHome=true` - Cannot access /home
- `ReadWritePaths` - Only /var/www/.../data is writable

### 3. Nginx Security
- Blocks access to `.git/`, `bitcoin_config.json`
- Security headers (XSS, frame options, MIME sniffing)
- JSON files served with no-cache headers
- Optional HTTPS/SSL support

### 4. File Permissions
- Service runs as `www-data` (unprivileged user)
- Config file only readable by owner
- Data directory properly restricted

## SSL/HTTPS Setup

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate (interactive)
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run

# Certificates auto-renew via cron/systemd timer
```

## Monitoring

### Check Service Health
```bash
# Quick status
systemctl is-active bitcoin-fetcher

# Detailed status
sudo systemctl status bitcoin-fetcher

# Recent logs
sudo journalctl -u bitcoin-fetcher -n 20
```

### Check Data Updates
```bash
# View current block height
jq '.block.height' /var/www/blockchain-matrix-visualizer/data/current_block.json

# Check last update time
stat -c %y /var/www/blockchain-matrix-visualizer/data/current_block.json

# Watch for updates
watch -n 5 'jq ".block.height" /var/www/blockchain-matrix-visualizer/data/current_block.json'
```

### Monitor Resource Usage
```bash
# Service memory usage
sudo systemctl status bitcoin-fetcher

# Disk usage
du -sh /var/www/blockchain-matrix-visualizer/data/

# Nginx connections
sudo ss -tulpn | grep nginx
```

## Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status bitcoin-fetcher

# View logs
sudo journalctl -u bitcoin-fetcher -n 50

# Test manually
cd /var/www/blockchain-matrix-visualizer
sudo -u www-data python3 bitcoin_fetcher.py
```

### Nginx Issues
```bash
# Test configuration
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log

# Verify site is enabled
ls -la /etc/nginx/sites-enabled/
```

### Permission Errors
```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer

# Fix permissions
sudo chmod 600 /var/www/blockchain-matrix-visualizer/bitcoin_config.json
sudo chmod 755 /var/www/blockchain-matrix-visualizer/data
sudo chmod 644 /var/www/blockchain-matrix-visualizer/data/*.json
```

### Cannot Connect to Bitcoin Node
```bash
# Test Tor
systemctl status tor

# Test RPC manually
curl -u rpcuser:rpcpass \
     --socks5-hostname 127.0.0.1:9050 \
     -d '{"jsonrpc":"2.0","id":"test","method":"getblockchaininfo","params":[]}' \
     -H 'content-type: text/plain;' \
     http://your-onion.onion:8332
```

## Updating the Application

```bash
# Stop service
sudo systemctl stop bitcoin-fetcher

# Update files
cd /var/www/blockchain-matrix-visualizer
sudo git pull  # or manually copy updated files

# Update dependencies if needed
sudo pip3 install -r requirements.txt --upgrade

# Restart service
sudo systemctl start bitcoin-fetcher

# Reload nginx if HTML/config changed
sudo systemctl reload nginx
```

## Backup and Restore

### Backup Configuration
```bash
# Backup config and data
sudo tar -czf bitcoin-visualizer-backup.tar.gz \
  /var/www/blockchain-matrix-visualizer/bitcoin_config.json \
  /var/www/blockchain-matrix-visualizer/config.json \
  /var/www/blockchain-matrix-visualizer/data/
```

### Restore Configuration
```bash
# Extract backup
sudo tar -xzf bitcoin-visualizer-backup.tar.gz -C /

# Fix permissions
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer
sudo chmod 600 /var/www/blockchain-matrix-visualizer/bitcoin_config.json

# Restart service
sudo systemctl restart bitcoin-fetcher
```

## Performance Tuning

### Reduce Resource Usage
Edit `/var/www/blockchain-matrix-visualizer/bitcoin_config.json`:
```json
{
  "poll_interval": 60,                    // Check less frequently
  "transaction_chunk_size": 5,            // Smaller chunks
  "max_transactions_per_block": 50        // Process fewer transactions
}
```

Then restart: `sudo systemctl restart bitcoin-fetcher`

### Nginx Caching (Advanced)
Add to nginx.conf for better performance:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g;
```

## Production Checklist

- [ ] SSL/HTTPS configured (certbot)
- [ ] Firewall configured (ufw allow 80,443)
- [ ] Service enabled on boot
- [ ] Logs rotating properly (/etc/logrotate.d/)
- [ ] Monitoring set up (optional: Prometheus, Grafana)
- [ ] Backups configured (automated)
- [ ] Domain DNS configured
- [ ] bitcoin_config.json permissions correct (600)
- [ ] Service running as www-data user
- [ ] Tor service enabled and running

## Support

For issues:
1. Check service logs: `sudo journalctl -u bitcoin-fetcher -f`
2. Check nginx logs: `sudo tail -f /var/log/nginx/*.log`
3. Test manually: `sudo -u www-data python3 bitcoin_fetcher.py`
4. Review [BITCOIN_NODE_SETUP.md](BITCOIN_NODE_SETUP.md)
5. Review [QUICKSTART.md](QUICKSTART.md)
