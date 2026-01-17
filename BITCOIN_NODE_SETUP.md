# Bitcoin Node Integration for Blockchain Matrix Visualizer

This guide explains how to set up the blockchain-matrix-visualizer on Ubuntu with nginx to pull block data directly from your Tor-only Bitcoin node.

## Architecture

The system consists of three components:

1. **Backend Service** (`bitcoin_fetcher.py`) - Runs as a systemd service, connects to your Bitcoin node via RPC, fetches block data, and writes it to a local JSON file
2. **Nginx Web Server** - Serves the static HTML/JS frontend and JSON data files
3. **Frontend Visualizer** (`index.html`) - Reads the JSON file and displays the matrix visualization

This architecture keeps your .onion address private and secure, as it's only stored in a local configuration file that's never exposed publicly.

## Quick Start (Automated Deployment)

For a complete automated deployment:

```bash
# Clone/upload your project to the server
cd /path/to/blockchain-matrix-visualizer

# Run the full deployment script
sudo ./deploy.sh
```

This will install all dependencies, configure nginx, set up the systemd service, and start everything.

## Manual Setup Instructions

### 1. Install System Dependencies

```bash
sudo apt update
sudo apt install -y python3 python3-pip nginx tor
```

### 2. Install Python Dependencies

```bash
pip3 install -r requirements.txt
```

This installs:
- `requests` - HTTP library for RPC calls
- `requests[socks]` - Tor proxy support

### 3. Start and Enable Tor

```bash
sudo systemctl enable tor
sudo systemctl start tor
sudo systemctl status tor
```

### 4. Configure Bitcoin Node Credentials

Create a `bitcoin_config.json` file by copying the example:

```bash
cp bitcoin_config.example.json bitcoin_config.json
```

Then edit `bitcoin_config.json` with your Bitcoin node details:

```bash
nano bitcoin_config.json
```

```json
{
  "rpc_url": "http://your-onion-address.onion:8332",
  "rpc_user": "your_rpc_username",
  "rpc_password": "your_rpc_password",
  
  "use_tor": true,
  "tor_proxy": "socks5h://127.0.0.1:9050",
  
  "poll_interval": 30,
  "output_dir": "./data",
  
  "transaction_chunk_size": 10,
  "max_transactions_per_block": 100
}
```

**Configuration Options:**

- `rpc_url` - Your Bitcoin Core RPC endpoint (can be .onion address)
- `rpc_user` - RPC username (from your bitcoin.conf)
- `rpc_password` - RPC password (from your bitcoin.conf)
- `use_tor` - Set to `true` to route requests through Tor
- `tor_proxy` - Tor SOCKS proxy address (default: `socks5h://127.0.0.1:9050`)
- `poll_interval` - How often to check for new blocks (seconds)
- `transaction_chunk_size` - Number of transactions per chunk (for iterative display)
- `max_transactions_per_block` - Maximum transactions to process per block

### 5. Ensure Tor is Running

If your Bitcoin node is only accessible via Tor, make sure Tor is running:

```bash
# Check if Tor is running
systemctl status tor

# View Tor logs
sudo journalctl -u tor -f
```

The default Tor SOCKS proxy runs on `127.0.0.1:9050`.

### 6. Configure Your Bitcoin Node

Ensure your Bitcoin Core node has RPC enabled. Add to your `bitcoin.conf`:

```conf
server=1
rpcuser=your_rpc_username
rpcpassword=your_rpc_password
rpcallowip=127.0.0.1
txindex=1
```

**Note:** `txindex=1` is optional but recommended for faster transaction lookups.

Restart Bitcoin Core after changes:

```bash
bitcoin-cli stop
bitcoind -daemon
```

### 7. Deploy to Web Directory

Copy your project to the nginx web directory:

```bash
sudo mkdir -p /var/www/blockchain-matrix-visualizer
sudo cp -r * /var/www/blockchain-matrix-visualizer/
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer
sudo chmod 600 /var/www/blockchain-matrix-visualizer/bitcoin_config.json
```

### 8. Configure Nginx

Copy the nginx configuration:

```bash
sudo cp nginx.conf /etc/nginx/sites-available/blockchain-matrix-visualizer
sudo ln -s /etc/nginx/sites-available/blockchain-matrix-visualizer /etc/nginx/sites-enabled/
```

Edit the configuration to set your domain:

```bash
sudo nano /etc/nginx/sites-available/blockchain-matrix-visualizer
```

Change `server_name your-domain.com;` to your actual domain or server IP.

Test and reload nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 9. Install as Systemd Service

For production use, install the fetcher as a systemd service:

```bash
sudo ./install_service.sh
```

Or manually:

```bash
# Copy service file
sudo cp bitcoin-fetcher.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable bitcoin-fetcher
sudo systemctl start bitcoin-fetcher

# Check status
sudo systemctl status bitcoin-fetcher
```

### 10. Configure the Frontend

The frontend is already configured to use local data. Verify `config.json` has:

```json
{
  "api": {
    "useLocalNode": true,
    ...
  }
}
```

### 11. Access the Visualizer

Open your web browser and navigate to:
- `http://your-server-ip/` or
- `http://your-domain.com/`

## Testing the Setup

### Test Bitcoin Fetcher (Development Mode)

Before installing as a service, test the fetcher:

```bash
cd /var/www/blockchain-matrix-visualizer
python3 bitcoin_fetcher.py
```

You should see output like:

```
2026-01-16 12:00:00 - INFO - Bitcoin Block Fetcher started
2026-01-16 12:00:00 - INFO - Checking for new blocks every 30 seconds
2026-01-16 12:00:00 - INFO - Connected to Bitcoin Core - Chain: main, Blocks: 932535
2026-01-16 12:00:01 - INFO - New block detected: 00000000000000...
2026-01-16 12:00:02 - INFO - Processing block 00000000000000...
2026-01-16 12:00:05 - INFO - Block data saved to ./data/current_block.json
2026-01-16 12:00:05 - INFO - Block 932535 processed successfully
```

Press Ctrl+C to stop, then install as a service.

## Features

### Transaction Chunking

The backend processes transactions in configurable chunks (default: 10 transactions per chunk). The visualizer automatically cycles through these chunks, allowing you to see different parts of the block's transaction data over time.

**Benefits:**
- View more transactions from a block without overwhelming the display
- Smooth iteration through block data
- Configurable chunk size for different display preferences

### Data Structure

The backend writes data in this format:

```json
{
  "block": {
    "hash": "...",
    "height": 932535,
    "version": 536870912,
    ...
  },
  "coinbase_ascii": "extracted coinbase text",
  "header_data": "concatenated header data for matrix",
  "transaction_chunks": [
    {
      "chunk_num": 0,
      "transaction_count": 10,
      "utxos": [
        {
          "address": "bc1q...",
          "amount_btc": 0.00123456,
          "txid": "...",
          "type": "output"
        }
      ]
    }
  ]
}
```

## Security Considerations

1. **Private Configuration** - `bitcoin_config.json` is added to `.gitignore` to prevent accidentally committing your .onion address and credentials
2. **Local-Only Access** - The Bitcoin node connection happens entirely on your local machine
3. **No Public Exposure** - Your .onion address is never exposed to the frontend or external services
4. **Tor Privacy** - All connections to your node go through Tor for additional privacy

## Troubleshooting

### "Connection refused" errors

- Verify Tor is running: `systemctl status tor`
- Check your Bitcoin node is accessible
- Test RPC connection manually:

```bash
curl -u rpcuser:rpcpassword \
     --socks5-hostname 127.0.0.1:9050 \
     -d '{"jsonrpc":"2.0","id":"test","method":"getblockchaininfo","params":[]}' \
     -H 'content-type: text/plain;' \
     http://your-onion.onion:8332
```

### "Failed to fetch status" in browser

- Ensure bitcoin-fetcher service is running: `sudo systemctl status bitcoin-fetcher`
- Check that `/var/www/blockchain-matrix-visualizer/data/current_block.json` exists
- Verify nginx configuration: `sudo nginx -t`
- Check nginx error logs: `sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log`
- Verify file permissions: `ls -la /var/www/blockchain-matrix-visualizer/data/`


## Service Management

### View Service Status

```bash
sudo systemctl status bitcoin-fetcher
```

### View Live Logs

```bash
sudo journalctl -u bitcoin-fetcher -f
```

### Restart Service

```bash
sudo systemctl restart bitcoin-fetcher
```

### Stop Service

```bash
sudo systemctl stop bitcoin-fetcher
```

### Disable Service (prevent auto-start on boot)

```bash
sudo systemctl disable bitcoin-fetcher
```

### Re-enable Service

```bash
sudo systemctl enable bitcoin-fetcher
```
### Service won't start

```bash
# Check service status
sudo systemctl status bitcoin-fetcher

# View detailed logs
sudo journalctl -u bitcoin-fetcher -n 50

# Check Python errors
cd /var/www/blockchain-matrix-visualizer
sudo -u www-data python3 bitcoin_fetcher.py
```

### Permission errors

```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/blockchain-matrix-visualizer

# Fix permissions
sudo chmod 600 /var/www/blockchain-matrix-visualizer/bitcoin_config.json
sudo chmod 755 /var/www/blockchain-matrix-visualizer/data
sudo chmod 644 /var/www/blockchain-matrix-visualizer/data/*.json
```

### Slow performance

- Reduce `max_transactions_per_block` in `bitcoin_config.json`
- Increase `poll_interval` to check less frequently
- Ensure your node has `txindex=1` enabled for faster lookups

## Switching Back to mempool.space

To switch back to using the public mempool.space API, edit `config.json`:

```bash
nano /var/www/blockchain-matrix-visualizer/config.json
```

Change:

```json
{
  "api": {
    "useLocalNode": false,
    ...
  }
}
```

Then reload the page in your browser.

## SSL/HTTPS Setup (Recommended)

For production deployments, use Let's Encrypt for free SSL certificates:

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate (follow prompts)
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

Certbot will automatically update your nginx configuration for HTTPS.

## Nginx Configuration Details

The included `nginx.conf` file provides:

- **Security headers** - XSS protection, frame options, content type sniffing prevention
- **Cache control** - JSON files always fetched fresh (no caching)
- **Static file caching** - CSS/JS/images cached for 7 days
- **Sensitive file protection** - Blocks access to `.git`, `bitcoin_config.json`, etc.
- **Logging** - Access and error logs for debugging

## File Structure on Server

```
/var/www/blockchain-matrix-visualizer/
├── bitcoin_fetcher.py              # Backend service
├── bitcoin_config.json             # Your credentials (protected)
├── bitcoin_config.example.json     # Template
├── bitcoin-fetcher.service         # Systemd service definition
├── nginx.conf                      # Nginx configuration template
├── setup.sh                        # Setup script
├── start_fetcher.sh               # Manual start script
├── install_service.sh             # Service installer
├── deploy.sh                      # Full deployment script
├── requirements.txt               # Python dependencies
├── config.json                    # Frontend configuration
├── index.html                     # Visualizer frontend
├── data/                          # Block data directory
│   ├── current_block.json         # Current block (read by frontend)
│   └── block_*.json               # Historical blocks
└── status/                        # Optional status monitoring
    └── status.json
```

## Advanced Configuration

### Custom Chunk Display

You can modify the chunk rotation behavior in [index.html](index.html) around line 1700.

### Processing More Transactions

Edit `/var/www/blockchain-matrix-visualizer/bitcoin_config.json`:

```json
{
  "transaction_chunk_size": 20,
  "max_transactions_per_block": 500
}
```

Then restart the service:

```bash
sudo systemctl restart bitcoin-fetcher
```

**Note:** Processing more transactions will increase CPU usage and file size.

## Monitoring

### Check if Service is Running

```bash
# Quick check
systemctl is-active bitcoin-fetcher

# Detailed status
sudo systemctl status bitcoin-fetcher
```

### Monitor Logs in Real-Time

```bash
# Follow service logs
sudo journalctl -u bitcoin-fetcher -f

# Show last 50 lines
sudo journalctl -u bitcoin-fetcher -n 50

# Show logs since boot
sudo journalctl -u bitcoin-fetcher -b
```

### Monitor Nginx Access

```bash
# Follow access log
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.access.log

# Follow error log
sudo tail -f /var/log/nginx/blockchain-matrix-visualizer.error.log
```

### Check Data File Updates

```bash
# Watch for file changes
watch -n 1 'ls -lh /var/www/blockchain-matrix-visualizer/data/current_block.json'

# View current block height
jq '.block.height' /var/www/blockchain-matrix-visualizer/data/current_block.json
```

## License

See [LICENSE](LICENSE) file.
