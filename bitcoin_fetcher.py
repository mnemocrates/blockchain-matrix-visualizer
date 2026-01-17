#!/usr/bin/env python3
"""
Bitcoin Block Data Fetcher for Matrix Visualizer
Fetches block data from a Bitcoin Core node via RPC and writes to JSON files.
"""

import json
import time
import logging
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
import requests
from requests.auth import HTTPBasicAuth

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class BitcoinRPCClient:
    """Client for interacting with Bitcoin Core RPC API."""
    
    def __init__(self, config: Dict):
        self.rpc_url = config['rpc_url']
        self.rpc_user = config['rpc_user']
        self.rpc_password = config['rpc_password']
        self.use_tor = config.get('use_tor', False)
        self.tor_proxy = config.get('tor_proxy', 'socks5h://127.0.0.1:9050')
        
        # Setup session with Tor proxy if needed
        self.session = requests.Session()
        if self.use_tor:
            self.session.proxies = {
                'http': self.tor_proxy,
                'https': self.tor_proxy
            }
        
        self.session.auth = HTTPBasicAuth(self.rpc_user, self.rpc_password)
        self.request_id = 0
    
    def call(self, method: str, params: List = None) -> Dict:
        """Make an RPC call to Bitcoin Core."""
        self.request_id += 1
        payload = {
            'jsonrpc': '2.0',
            'id': self.request_id,
            'method': method,
            'params': params or []
        }
        
        try:
            response = self.session.post(
                self.rpc_url,
                json=payload,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()
            
            if 'error' in result and result['error']:
                raise Exception(f"RPC error: {result['error']}")
            
            return result.get('result')
        
        except requests.exceptions.RequestException as e:
            logger.error(f"RPC call failed ({method}): {e}")
            raise
    
    def get_blockchain_info(self) -> Dict:
        """Get blockchain information."""
        return self.call('getblockchaininfo')
    
    def get_best_block_hash(self) -> str:
        """Get the hash of the best (tip) block."""
        return self.call('getbestblockhash')
    
    def get_block(self, block_hash: str, verbosity: int = 1) -> Dict:
        """Get block data by hash."""
        return self.call('getblock', [block_hash, verbosity])
    
    def get_raw_transaction(self, txid: str, verbose: bool = True) -> Dict:
        """Get raw transaction data."""
        return self.call('getrawtransaction', [txid, verbose])


class BlockDataProcessor:
    """Process Bitcoin block data for the matrix visualizer."""
    
    def __init__(self, rpc_client: BitcoinRPCClient, config: Dict):
        self.rpc = rpc_client
        self.config = config
        self.output_dir = Path(config.get('output_dir', './data'))
        self.output_dir.mkdir(exist_ok=True)
        
        # Transaction chunking configuration
        self.chunk_size = config.get('transaction_chunk_size', 10)
        self.max_transactions = config.get('max_transactions_per_block', 100)
    
    def hex_to_ascii_safe(self, hex_str: str) -> str:
        """Convert hex string to ASCII, keeping only printable characters."""
        if not hex_str:
            return ''
        
        try:
            # Remove any non-hex characters
            cleaned = ''.join(c for c in hex_str if c in '0123456789abcdefABCDEF')
            
            # Convert hex pairs to characters
            result = ''
            for i in range(0, len(cleaned), 2):
                if i + 1 < len(cleaned):
                    byte = int(cleaned[i:i+2], 16)
                    if 32 <= byte <= 126:  # Printable ASCII range
                        result += chr(byte)
            
            return result.lower()
        except Exception as e:
            logger.warning(f"Failed to convert hex to ASCII: {e}")
            return ''
    
    def process_coinbase_transaction(self, txid: str) -> str:
        """Extract ASCII data from coinbase transaction."""
        try:
            tx = self.rpc.get_raw_transaction(txid)
            
            # Get coinbase scriptSig
            if tx.get('vin') and len(tx['vin']) > 0:
                vin0 = tx['vin'][0]
                if 'coinbase' in vin0:
                    return self.hex_to_ascii_safe(vin0['coinbase'])
                elif 'scriptSig' in vin0 and 'hex' in vin0['scriptSig']:
                    return self.hex_to_ascii_safe(vin0['scriptSig']['hex'])
        
        except Exception as e:
            logger.warning(f"Failed to process coinbase tx {txid}: {e}")
        
        return ''
    
    def process_transaction_chunk(self, txids: List[str], chunk_num: int) -> Dict:
        """Process a chunk of transactions and extract UTXO data."""
        utxo_strings = []
        
        for txid in txids:
            try:
                tx = self.rpc.get_raw_transaction(txid)
                
                # Process outputs (UTXOs being created)
                if 'vout' in tx:
                    for vout in tx['vout']:
                        value_btc = vout.get('value', 0)
                        
                        # Get address from scriptPubKey
                        spk = vout.get('scriptPubKey', {})
                        address = 'unknown'
                        if 'address' in spk:
                            address = spk['address']
                        elif 'addresses' in spk and spk['addresses']:
                            address = spk['addresses'][0]
                        
                        utxo_strings.append({
                            'address': address,
                            'amount_btc': value_btc,
                            'txid': txid,
                            'type': 'output'
                        })
                
                # Process inputs (UTXOs being spent)
                if 'vin' in tx:
                    for vin in tx['vin']:
                        # Skip coinbase inputs
                        if 'coinbase' in vin:
                            continue
                        
                        # For regular inputs, we need to look up the previous tx
                        # For efficiency, we'll skip this in the first version
                        # as it requires additional RPC calls
                        pass
            
            except Exception as e:
                logger.warning(f"Failed to process transaction {txid}: {e}")
        
        return {
            'chunk_num': chunk_num,
            'transaction_count': len(txids),
            'utxos': utxo_strings,
            'processed_at': datetime.utcnow().isoformat() + 'Z'
        }
    
    def process_block(self, block_hash: str) -> Dict:
        """Process a complete block and return structured data."""
        logger.info(f"Processing block {block_hash[:16]}...")
        
        # Get block data with transaction IDs
        block = self.rpc.get_block(block_hash, 2)  # Verbosity 2 includes transaction data
        
        # Extract basic block info
        block_info = {
            'hash': block['hash'],
            'height': block['height'],
            'version': block['version'],
            'merkle_root': block['merkleroot'],
            'timestamp': block['time'],
            'mediantime': block.get('mediantime'),
            'nonce': block['nonce'],
            'bits': block['bits'],
            'difficulty': block['difficulty'],
            'size': block['size'],
            'weight': block['weight'],
            'tx_count': block['nTx'],
            'previousblockhash': block.get('previousblockhash', ''),
            'nextblockhash': block.get('nextblockhash', ''),
        }
        
        # Get transaction IDs
        txids = [tx['txid'] if isinstance(tx, dict) else tx for tx in block.get('tx', [])]
        
        # Process coinbase transaction for ASCII data
        coinbase_ascii = ''
        if txids:
            coinbase_ascii = self.process_coinbase_transaction(txids[0])
        
        # Prepare block header data (for left side of matrix)
        header_data = ' '.join([
            block_info['hash'],
            block_info['merkle_root'],
            f"version{block_info['version']}",
            f"bits{block_info['bits']}",
            f"nonce{block_info['nonce']}",
            f"difficulty{block_info['difficulty']}",
            f"timestamp{block_info['timestamp']}",
            f"height{block_info['height']}",
            coinbase_ascii
        ]).lower()
        
        # Remove non-alphanumeric characters (except spaces)
        header_data = ''.join(c for c in header_data if c.isalnum() or c == ' ')
        
        # Process transactions in chunks
        transaction_chunks = []
        tx_limit = min(self.max_transactions, len(txids))
        
        for chunk_num, i in enumerate(range(1, tx_limit, self.chunk_size)):  # Skip coinbase (index 0)
            chunk_txids = txids[i:i + self.chunk_size]
            if chunk_txids:
                chunk_data = self.process_transaction_chunk(chunk_txids, chunk_num)
                transaction_chunks.append(chunk_data)
        
        # Compile final block data
        return {
            'block': block_info,
            'coinbase_ascii': coinbase_ascii,
            'header_data': header_data,
            'transaction_chunks': transaction_chunks,
            'total_transactions': len(txids),
            'processed_transactions': min(tx_limit, len(txids)),
            'updated_at': datetime.utcnow().isoformat() + 'Z'
        }
    
    def save_block_data(self, block_data: Dict):
        """Save block data to JSON file."""
        output_file = self.output_dir / 'current_block.json'
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(block_data, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Block data saved to {output_file}")
            
            # Also save a timestamped version for history
            block_height = block_data['block']['height']
            history_file = self.output_dir / f'block_{block_height}.json'
            with open(history_file, 'w', encoding='utf-8') as f:
                json.dump(block_data, f, indent=2, ensure_ascii=False)
        
        except Exception as e:
            logger.error(f"Failed to save block data: {e}")
            raise


class BitcoinFetcher:
    """Main fetcher service."""
    
    def __init__(self, config_path: str = 'bitcoin_config.json'):
        self.config_path = Path(config_path)
        self.config = self.load_config()
        self.rpc_client = BitcoinRPCClient(self.config)
        self.processor = BlockDataProcessor(self.rpc_client, self.config)
        self.last_block_hash = None
    
    def load_config(self) -> Dict:
        """Load configuration from file."""
        if not self.config_path.exists():
            logger.error(f"Configuration file not found: {self.config_path}")
            raise FileNotFoundError(f"Please create {self.config_path}")
        
        with open(self.config_path, 'r') as f:
            return json.load(f)
    
    def check_for_new_block(self) -> Optional[str]:
        """Check if there's a new block."""
        try:
            current_hash = self.rpc_client.get_best_block_hash()
            
            if current_hash != self.last_block_hash:
                logger.info(f"New block detected: {current_hash[:16]}...")
                return current_hash
            
            return None
        
        except Exception as e:
            logger.error(f"Failed to check for new block: {e}")
            return None
    
    def run(self):
        """Main run loop."""
        logger.info("Bitcoin Block Fetcher started")
        logger.info(f"Checking for new blocks every {self.config.get('poll_interval', 30)} seconds")
        
        # Test connection
        try:
            info = self.rpc_client.get_blockchain_info()
            logger.info(f"Connected to Bitcoin Core - Chain: {info['chain']}, Blocks: {info['blocks']}")
        except Exception as e:
            logger.error(f"Failed to connect to Bitcoin Core: {e}")
            return
        
        # Main loop
        while True:
            try:
                new_block_hash = self.check_for_new_block()
                
                if new_block_hash:
                    block_data = self.processor.process_block(new_block_hash)
                    self.processor.save_block_data(block_data)
                    self.last_block_hash = new_block_hash
                    logger.info(f"Block {block_data['block']['height']} processed successfully")
                
                # Wait before checking again
                time.sleep(self.config.get('poll_interval', 30))
            
            except KeyboardInterrupt:
                logger.info("Shutting down...")
                break
            
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(10)  # Wait a bit before retrying


def main():
    """Entry point."""
    import sys
    
    config_file = sys.argv[1] if len(sys.argv) > 1 else 'bitcoin_config.json'
    
    try:
        fetcher = BitcoinFetcher(config_file)
        fetcher.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
