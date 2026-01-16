# Bitcoin Block Matrix Visualizer

A real-time Matrix-style visualization of Bitcoin blockchain data, featuring falling character streams that display block headers and UTXO transaction details.

## Features

- **Matrix Rain Effect**: Character streams with variable trail lengths (5-80% screen height) and exponential fade
- **Live Bitcoin Data**: Real-time block data from [mempool.space](https://mempool.space) API
- **Node Monitor Panel**: Real-time status monitoring for Tor-only Bitcoin/Electrs/LND nodes
- **Dual Data Display**:
  - Left 25%: Block header information (hash, merkle root, version, bits, nonce, difficulty, timestamp, height, coinbase)
  - Right 75%: UTXO transaction data (addresses, amounts, transaction hashes)
- **Bitcoin Amount Highlighting**: Bitcoin symbols (₿) and amounts rendered in gold (#FFD700)
- **Stable Character Rendering**: Character history buffers prevent rapid cycling for improved readability
- **Color Gradient**: Green color gradient across UTXO columns
- **Interactive Panels**: Access Block Details and Node Monitor via menu (press `/`)
- **Keyboard Controls**: Press 's' to toggle UI visibility, '/' for menu, ESC to close panels
- **Responsive Design**: Adapts to window resizing

## Data Source

All blockchain data is fetched from the [mempool.space API](https://mempool.space/docs/api/rest):
- `/api/blocks/tip/hash` - Latest block hash
- `/api/block/{hash}` - Block details
- `/api/block/{hash}/txids` - Transaction IDs in block
- `/api/tx/{txid}` - Individual transaction details (first 15 transactions)

Data refreshes automatically every 30 seconds.

## Deployment

### Local Development

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd blockchain-matrix-visualizer
   ```

2. Open `index.html` in a modern web browser:
   ```bash
   # On Windows
   start index.html
   
   # On macOS
   open index.html
   
   # On Linux
   xdg-open index.html
   ```

## Configuration

All visualization settings are stored in `config.json`, making it easy to customize the experience without modifying code.

### Configuration File Structure

```json
{
  "display": {
    "headerColumnPercentage": 0.25,    // Portion of screen for block header (0.0-1.0)
    "showUIOnLoad": false,              // Show info panel and status on page load
    "initiallyCollapsed": true          // Start with info panel collapsed
  },
  "matrix": {
    "fontSize": 18,                     // Character size in pixels
    "matrixSpeed": 0.5,                 // Falling speed (higher = faster)
    "trailLengthMin": 5,                // Minimum trail length in characters
    "trailLengthMaxPercent": 0.8,       // Maximum trail as % of screen height
    "fadeStartOpacity": 0.5,            // Starting opacity for trails (0.0-1.0)
    "fadeExponent": 2,                  // Fade curve (higher = faster fade)
    "backgroundFadeAlpha": 0.15,        // Background fade effect (0.0-1.0)
    "resetProbability": 0.975           // Probability to NOT reset column
  },
  "colors": {
    "primaryColor": "#00ff7f",          // Main matrix green
    "goldColor": "#FFD700",             // Bitcoin amount highlighting
    "gradientStartRGB": [0, 170, 85],   // UTXO gradient start [R, G, B]
    "gradientEndRGB": [0, 136, 68]      // UTXO gradient end [R, G, B]
  },
  "api": {
    "apiBase": "https://mempool.space/api",
    "blockRefreshInterval": 30000,      // Check for new blocks (ms)
    "ageUpdateInterval": 1000,          // Update block age display (ms)
    "transactionFetchLimit": 15         // Number of transactions to fetch
  },
  "keyboard": {
    "toggleKey": "s"                    // Key to toggle UI visibility
  }
}
```

### Customization Examples

**Faster, shorter trails:**
```json
"matrix": {
  "matrixSpeed": 1.0,
  "trailLengthMin": 3,
  "trailLengthMaxPercent": 0.5
}
```

**Show UI on load:**
```json
"display": {
  "showUIOnLoad": true,
  "initiallyCollapsed": false
}
```

**More transaction data:**
```json
"api": {
  "transactionFetchLimit": 30
}
```

**Custom color scheme:**
```json
"colors": {
  "primaryColor": "#00ffff",
  "gradientStartRGB": [0, 255, 255],
  "gradientEndRGB": [0, 128, 255]
}
```

**Note:** The application falls back to default values if `config.json` is missing or invalid.

## Usage

### Keyboard Shortcuts

- **/** - Navigate back: Opens menu → Closes panel (returns to menu) → Closes menu
- **b** - (when menu open) Open Block Details panel
- **n** - (when menu open) Open Node Monitor panel
- **b/l/t/e** - (when Node Monitor open) Switch between service tabs (Bitcoin/Lightning/Tor/Electrs)
- **s** - Toggle overlay panel and status indicator visibility
- **ESC** - Alternative close key (same behavior as /)

### Interactive Elements

- **Click overlay panel** - Expand/collapse block details
- **Hover overlay** - Enhanced glow effect
- **Panel navigation** - Use keyboard shortcuts or click menu items

## Node Monitor

The Node Monitor panel provides real-time status monitoring for Tor-only Bitcoin nodes running Bitcoin Core, LND (Lightning Network Daemon), Electrs, and Tor.

### Setup

1. Create a `status` directory in the same location as `index.html`:
   ```bash
   mkdir status
   ```

2. Configure your node monitoring script to output status to `./status/status.json`

3. The panel will automatically refresh every 30 seconds while open

### Status Display Features

- **Fixed-Height Panel**: Panel size remains constant when switching between tabs
- **Tabbed Interface**: One tab per service group (Bitcoin Core, Lightning Network, Tor, Electrs)
  - Click tab or press underlined letter key to switch
  - Color-coded status indicator on each tab shows worst status in that group
  - Active tab highlighted with enhanced border and glow
- **Visual Status Indicators**: Color-coded badges (OK=green, WARN=yellow, ERROR=red)
- **Expandable Details**: Click any check to view detailed metrics
- **Staleness Indicator**: Color-coded timestamp showing data freshness
  - 🟢 Green: Updated < 8 minutes ago
  - 🟡 Yellow: Updated 8-15 minutes ago
  - 🔴 Red: Updated > 15 minutes ago
- **Glitch Effect**: Visual transition effect when status updates
- **Dynamic Navigation**: Keyboard shortcuts automatically adapt to available service groups

### Status File Format

The `status.json` file should follow this structure:

```json
{
  "node": "identifier",
  "hostname": "node-hostname",
  "timestamp": "2026-01-16T17:35:29Z",
  "checks": {
    "check_name": {
      "status": "OK|WARN|ERROR",
      "message": "Human-readable status message",
      "updated": "2026-01-16T17:35:01Z",
      "metrics": {
        "metric_key": "value"
      }
    }
  }
}
```

Supported check prefixes:
- `bitcoin_*` - Bitcoin Core checks
- `lnd_*` - Lightning Network Daemon checks
- `tor_*` - Tor network checks
- `electrs_*` - Electrs server checks

## Web Hosting

Deploy both `index.html` and `config.json` to any static web hosting service:

- **GitHub Pages**: Push to a GitHub repository and enable Pages
- **Netlify**: Drag and drop the files or connect to your repository
- **Vercel**: Deploy with `vercel deploy`
- **AWS S3**: Upload to an S3 bucket with static website hosting enabled
- **Any HTTP server**: Apache, Nginx, or simple Python server

Example with Python:
```bash
python -m http.server 8000
# Visit http://localhost:8000
```

**Important:** Both `index.html` and `config.json` must be in the same directory for the application to load configuration properly.

## Technical Details

### Animation

- **Frame Rate**: 60 FPS via `requestAnimationFrame`
- **Font Size**: 18px monospace
- **Drop Speed**: 0.5 cells/frame (50% slower than standard)
- **Character Positioning**: `Math.floor()` snapping for grid alignment
- **Trail Fade**: Exponential decay starting at 50% opacity

### Data Processing

- Block header fields separated by spaces
- UTXO data includes inputs (prevout) and outputs (vout)
- Bitcoin amounts converted from satoshis to BTC (8 decimal places)
- Character pools assigned per-column with color tracking
- Gold highlighting for bitcoin symbol (₿) and following digits

### Browser Compatibility

Requires a modern browser with support for:
- HTML5 Canvas
- ES6+ JavaScript (arrow functions, async/await, template literals)
- CSS3 (transitions, backdrop-filter)
- Fetch API

## Performance

- Character history buffers capped at screen height
- Configuration UI editor
- Mobile touch controls
- Screenshot/export functionality
- Additional color themes and presets clearing

## License

MIT License - see [LICENSE](LICENSE) file for details

## Credits

- Inspired by [tidwall/digitalrain](https://github.com/tidwall/digitalrain)
- Bitcoin data provided by [mempool.space](https://mempool.space)

## Contributing

Contributions welcome! Areas for enhancement:
- Individual column speeds (while maintaining readability)
- Additional blockchain networks
- User-configurable parameters
- Mobile touch controls
- Screenshot/export functionality
