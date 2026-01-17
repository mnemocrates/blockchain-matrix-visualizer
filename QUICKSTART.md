# Quick Reference Guide

## Quick Start (Local Node on Ubuntu)

```bash
# 1. Setup (first time only)
./setup.sh

# 2. Edit your configuration
nano bitcoin_config.json

# 3. Start the fetcher (development)
python3 bitcoin_fetcher.py

# 4. Or install as a service (production)
sudo ./install_service.sh

# 5. Access via nginx
http://your-server-ip/
```

## Full Automated Deployment

```bash
# Deploy everything (nginx + systemd service)
sudo ./deploy.sh
```

## Configuration Files

### bitcoin_config.json (Private - Your Node Credentials)
```json
{
  "rpc_url": "http://your-onion.onion:8332",
  "rpc_user": "your_username",
  "rpc_password": "your_password",
  "use_tor": true,
  "poll_interval": 30,
  "transaction_chunk_size": 10,
  "max_transactions_per_block": 100
}
```

### config.json (Frontend Display Settings)
```json
{
  "api": {
    "useLocalNode": true,  // false = use mempool.space
    "blockRefreshInterval": 30000
  }
}
```

## Common Commands

### Service Management

```bash
# Start service
sudo systemctl start bitcoin-fetcher

# Stop service
sudo systemctl stop bitcoin-fetcher

# Restart service
sudo systemctl restart bitcoin-fetcher

# Check status
sudo systemctl status bitcoin-fetcher

# View logs
sudo journalctl -u bitcoin-fetcher -f

# Enable auto-start on boot
sudo systemctl enable bitcoin-fetcher

# Disable auto-start
sudo systemctl disable bitcoin-fetcher
```

### Development Mode

```bash
# Run manually (not as service)
cd /var/www/blockchain-matrix-visualizer
python3 bitcoin_fetcher.py

# Stop with Ctrl+C
```

### Nginx Management

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# View access logs
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.access.log

# View error logs
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log
```

## Keyboard Shortcuts (Frontend)

| Key | Action |
|-----|--------|
| `s` | Toggle UI visibility |
| `/` | Open menu |
| `ESC` | Close menu/panel |

## Data Flow

```
Your Bitcoin Node → bitcoin_fetcher.py → data/current_block.json → nginx → Browser → Matrix Display
```

## File Locations

```
/var/www/blockchain-matrix-visualizer/
├── bitcoin_fetcher.py           # Backend service (runs as systemd service)
├── bitcoin_config.json          # Your private config (edit this)
├── index.html                   # Frontend (served by nginx)
├── config.json                  # Display settings
├── data/
│   └── current_block.json       # Current block data
├── setup.sh                     # Setup wizard
├── deploy.sh                    # Full deployment script
└── install_service.sh           # Service installer
```

## Nginx Config Location

```
/etc/nginx/sites-available/blockchain-matrix-visualizer
/etc/nginx/sites-enabled/blockchain-matrix-visualizer (symlink)
```

## Systemd Service Location

```
/etc/systemd/system/bitcoin-fetcher.service
```

## Troubleshooting

### Can't connect to node

```bash
# Test RPC connection manually
curl -u rpcuser:rpcpass \
     --socks5-hostname 127.0.0.1:9050 \
     -d '{"jsonrpc":"2.0","id":"test","method":"getblockchaininfo","params":[]}' \
     -H 'content-type: text/plain;' \
     http://your-onion.onion:8332
```

### Service crashes

```bash
# Check service logs
sudo journalctl -u bitcoin-fetcher -n 50

# Check for errors
sudo journalctl -u bitcoin-fetcher -p err

# Verify config file is valid JSON
cat bitcoin_config.json | python3 -m json.tool

# Test manually
cd /var/www/blockchain-matrix-visualizer
sudo -u www-data python3 bitcoin_fetcher.py
```

### No data showing in visualizer

```bash
# Check if data file exists
ls -la /var/www/blockchain-matrix-visualizer/data/current_block.json


Edit `/var/www/blockchain-matrix-visualizer/bitcoin_config.json`:

```json
{
  "transaction_chunk_size": 5,        // Reduce chunk size
  "max_transactions_per_block": 50,   // Process fewer transactions
  "poll_interval": 60                 // Check less frequently
}
```

Then restart:

```bash
sudo systemctl restart bitcoin-fetcher Check nginx logs
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log

# Check browser console (F12) for JavaScript errors
```

### Permission errors

```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer

# Fix specific permissions
sudo chmod 600 /var/www/blockchain-matrix-visualizer/bitcoin_config.json
sudo chmod 755 /var/www/blockchain-matrix-visualizer/data
sudo chmod 644 /var/www/blockchain-matrix-visualizer/data/*.json
```

### Slow performance
Edit `bitcoin_config.json`:
```json
{
  "transaction_chunk_size": 5,        // Reduce chunk size

Edit `/var/www/blockchain-matrix-visualizer/config.json`:

```json
{"api": {"useLocalNode": true}}
```

### Use mempool.space

Edit `/var/www/blockchain-matrix-visualizer/config.json`:

```json
{"api": {"useLocalNode": false}}
```

Then reload the page in your browser (no restart needed)

### Use mempool.space
Edit `config.json`:
```json
{"api": {"useLocalNode": false}}
```

Then refresh the browser.

## Bitcoin Core Configuration

Add to your `bitcoin.conf`:
```conf
server=1
rpcuser=your_username
rpcpassword=your_strong_password
rpcallowip=127.0.0.1
txindex=1  # Optional but recommended
```

Restart Bitcoin Core after changes.

## Getting Help

1. **Setup Issues**: See [BITCOIN_NODE_SETUP.md](BITCOIN_NODE_SETUP.md)
2. **Implementation Details**: See [IMPLEMENTATION.md](IMPLEMENTATION.md)
3. **General Usage**: See [README.md](README.md)

## Status Indicators

### Frontend Status Messages
- "Fetching block from local node…" = Working correctly
- "Local connection error" = Fetcher not running or data file missing
- "chunk 2/10" = Cycling through transaction chunks

### Backend Console Output
```
INFO - Bitcoin Block Fetcher started           ✓ Service started
INFO - Connected to Bitcoin Core              ✓ RPC working
INFO - New block detected                     ✓ Found new block
INFO - Block 932535 processed successfully    ✓ Data saved
```

## Performance Tips

1. **Enable txindex** on Bitcoin Core for faster lookups
2. **Reduce chunk size** if fetching is slow
3. **Increase poll interval** to reduce RPC load
4. **Run on SSD** for faster file I/O
5. **Use local node** (not .onion) if on same machine
bash
# Quick test if everything is working
jq '.block.height' /var/www/blockchain-matrix-visualizer/data/current_block.json

# Watch for new blocks (updates every 5 seconds)
watch -n 5 'jq "{height: .block.height, timestamp: .block.timestamp, tx_count: .block.tx_count}" /var/www/blockchain-matrix-visualizer/data/current_block.json'

# Check how many chunks are available
jq '.transaction_chunks | length' /var/www/blockchain-matrix-visualizer/data/current_block.json

# See current Bitcoin Core block height
bitcoin-cli getblockcount

# Monitor service memory usage
ps aux | grep bitcoin_fetcher.py

# Check disk usage of data directory
du -sh /var/www/blockchain-matrix-visualizer/data/
```

## SSL/HTTPS Setup

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run

# Force renewal (if needed)
sudo certbot renew --force-renewaler running as a Windows Service using [NSSM](https://nssm.cc/):

```powershell
# Install NSSM
choco install nssm

# Create service
nssm install BitcoinFetcher "C:\Python\python.exe" "C:\path\to\bitcoin_fetcher.py"
nssm set BitcoinFetcher AppDirectory "C:\path\to\blockchain-matrix-visualizer"
nssm start BitcoinFetcher

# Check status
nssm status BitcoinFetcher
```
