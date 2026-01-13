# Bitcoin Block Matrix Visualizer

A real-time Matrix-style visualization of Bitcoin blockchain data, featuring falling character streams that display block headers and UTXO transaction details.

## Features

- **Matrix Rain Effect**: Character streams with variable trail lengths (5-80% screen height) and exponential fade
- **Live Bitcoin Data**: Real-time block data from [mempool.space](https://mempool.space) API
- **Dual Data Display**:
  - Left 25%: Block header information (hash, merkle root, version, bits, nonce, difficulty, timestamp, height, coinbase)
  - Right 75%: UTXO transaction data (addresses, amounts, transaction hashes)
- **Bitcoin Amount Highlighting**: Bitcoin symbols (₿) and amounts rendered in gold (#FFD700)
- **Stable Character Rendering**: Character history buffers prevent rapid cycling for improved readability
- **Color Gradient**: Green color gradient across UTXO columns
- **Keyboard Controls**: Press 's' to toggle UI visibility
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

### Web Hosting

Deploy the `index.html` file to any static web hosting service:

- **GitHub Pages**: Push to a GitHub repository and enable Pages
- **Netlify**: Drag and drop the file or connect to your repository
- **Vercel**: Deploy with `vercel deploy`
- **AWS S3**: Upload to an S3 bucket with static website hosting enabled
- **Any HTTP server**: Apache, Nginx, or simple Python server

Example with Python:
```bash
python -m http.server 8000
# Visit http://localhost:8000
```

## Usage

### Keyboard Shortcuts

- **s** - Toggle overlay panel and status indicator visibility

### Interactive Elements

- **Click overlay panel** - Expand/collapse block details
- **Hover overlay** - Enhanced glow effect

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
- Efficient rendering with position change detection
- Color arrays pre-computed per character pool
- Background fade optimizes trail clearing

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
