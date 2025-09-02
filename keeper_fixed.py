#!/usr/bin/env python3
"""
FlashPeg Arbitrage Keeper Bot - Fixed Version
Handles missing dependencies gracefully for Render deployment
"""

import os
import sys
import time
import json
import logging
from datetime import datetime
from threading import Thread
from http.server import HTTPServer, BaseHTTPRequestHandler

# Try to import web3, fallback if not available
try:
    from web3 import Web3
    WEB3_AVAILABLE = True
except ImportError:
    print("WARNING: web3 not available - running in demo mode")
    WEB3_AVAILABLE = False

# Try to import dotenv, fallback if not available
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("WARNING: python-dotenv not available - skipping .env loading")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('flashpeg-keeper')

# Global status for health checks
keeper_status = {
    'running': False,
    'last_check': None,
    'successful_arbs': 0,
    'failed_arbs': 0,
    'wallet_address': None,
    'error': None,
    'web3_available': WEB3_AVAILABLE
}


class HealthCheckHandler(BaseHTTPRequestHandler):
    """HTTP handler for health checks and status"""
    
    def do_GET(self):
        if self.path == '/health':
            status_code = 200 if (keeper_status['running'] or not keeper_status.get('error')) else 503
            self.send_response(status_code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'healthy' if status_code == 200 else 'unhealthy',
                'timestamp': datetime.now().isoformat(),
                'uptime_seconds': time.time() - keeper_status.get('start_time', time.time()),
                **keeper_status
            }
            self.wfile.write(json.dumps(response, indent=2).encode())
        
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'name': 'FlashPeg Arbitrage Keeper',
                'version': '1.0.0',
                'status': 'running' if keeper_status['running'] else 'initializing',
                'web3_available': WEB3_AVAILABLE,
                'environment': {
                    'rpc_configured': bool(os.getenv('MAINNET_RPC_URL')),
                    'wallet_configured': bool(os.getenv('KEEPER_PRIVATE_KEY')),
                    'steth_contract': bool(os.getenv('ARB_STETH_CONTRACT')),
                    'dai_contract': bool(os.getenv('ARB_DAI_CONTRACT'))
                }
            }
            self.wfile.write(json.dumps(response, indent=2).encode())
        
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Not found'}).encode())
    
    def log_message(self, format, *args):
        # Log requests for debugging
        logger.info(f"HTTP: {format % args}")


class ArbitrageKeeper:
    """Main keeper bot class with graceful error handling"""
    
    def __init__(self):
        keeper_status['start_time'] = time.time()
        
        # Get environment variables
        self.rpc_url = os.getenv('MAINNET_RPC_URL')
        self.private_key = os.getenv('KEEPER_PRIVATE_KEY')
        self.steth_contract = os.getenv('ARB_STETH_CONTRACT')
        self.dai_contract = os.getenv('ARB_DAI_CONTRACT')
        
        # Configuration with defaults
        self.min_profit_usd = int(os.getenv('MIN_PROFIT_USD', '100'))
        self.max_gas_gwei = int(os.getenv('MAX_GAS_PRICE_GWEI', '50'))
        self.poll_interval = int(os.getenv('POLL_INTERVAL_MS', '5000')) / 1000
        
        # Initialize Web3 if available and configured
        self.w3 = None
        self.account = None
        
        if not WEB3_AVAILABLE:
            logger.warning("Web3 not available - running in demo mode")
            keeper_status['error'] = "Web3 library not available"
            return
        
        if not self.rpc_url:
            logger.warning("MAINNET_RPC_URL not configured - demo mode")
            keeper_status['error'] = "RPC URL not configured"
            return
            
        if not self.private_key:
            logger.warning("KEEPER_PRIVATE_KEY not configured - demo mode")
            keeper_status['error'] = "Private key not configured"
            return
        
        try:
            # Initialize Web3
            self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
            
            # Test connection
            if self.w3.is_connected():
                logger.info("✅ Connected to Ethereum network")
                
                # Set up account
                self.account = self.w3.eth.account.from_key(self.private_key)
                self.wallet_address = self.account.address
                keeper_status['wallet_address'] = self.wallet_address
                
                # Get wallet balance
                balance = self.w3.eth.get_balance(self.wallet_address)
                balance_eth = self.w3.from_wei(balance, 'ether')
                logger.info(f"Wallet: {self.wallet_address}")
                logger.info(f"Balance: {balance_eth:.6f} ETH")
                
                # Log contract status
                if self.steth_contract:
                    logger.info(f"stETH Contract: {self.steth_contract}")
                if self.dai_contract:
                    logger.info(f"DAI Contract: {self.dai_contract}")
                    
                keeper_status['error'] = None
                
            else:
                logger.error("❌ Failed to connect to Ethereum network")
                keeper_status['error'] = "Cannot connect to RPC"
                
        except Exception as e:
            logger.error(f"❌ Initialization failed: {e}")
            keeper_status['error'] = str(e)
    
    def check_opportunities(self):
        """Check for arbitrage opportunities"""
        if not self.w3 or not self.w3.is_connected():
            logger.debug("Skipping opportunity check - no Web3 connection")
            return []
        
        opportunities = []
        
        try:
            # Get current block for logging
            block = self.w3.eth.get_block('latest')
            logger.debug(f"Checking opportunities at block {block['number']}")
            
            # In production, would implement actual arbitrage detection here
            # For now, just simulate checking
            
            # Check gas price
            gas_price = self.w3.eth.gas_price
            gas_price_gwei = self.w3.from_wei(gas_price, 'gwei')
            
            if gas_price_gwei > self.max_gas_gwei:
                logger.info(f"Gas price too high: {gas_price_gwei:.2f} gwei (max: {self.max_gas_gwei})")
            else:
                logger.debug(f"Gas price acceptable: {gas_price_gwei:.2f} gwei")
            
        except Exception as e:
            logger.error(f"Error checking opportunities: {e}")
            keeper_status['failed_arbs'] += 1
        
        return opportunities
    
    def monitor_loop(self):
        """Main monitoring loop"""
        keeper_status['running'] = True
        logger.info("🚀 Arbitrage Keeper started")
        
        if keeper_status.get('error'):
            logger.warning(f"Running with limitations: {keeper_status['error']}")
        
        iteration = 0
        while keeper_status['running']:
            try:
                iteration += 1
                keeper_status['last_check'] = datetime.now().isoformat()
                
                # Check for opportunities
                opportunities = self.check_opportunities()
                
                # Log periodic status
                if iteration % 12 == 0:  # Every minute at 5s intervals
                    logger.info(f"Status - Iterations: {iteration}, "
                              f"Success: {keeper_status['successful_arbs']}, "
                              f"Failed: {keeper_status['failed_arbs']}")
                
                if not opportunities:
                    logger.debug("No profitable opportunities found")
                
                # Execute opportunities (placeholder)
                for opp in opportunities:
                    logger.info(f"Would execute: {opp}")
                    keeper_status['successful_arbs'] += 1
                
            except Exception as e:
                logger.error(f"Error in monitor loop: {e}")
                keeper_status['error'] = str(e)
            
            # Wait before next check
            time.sleep(self.poll_interval)
    
    def start(self):
        """Start the keeper monitoring"""
        self.monitor_loop()


def run_health_server():
    """Run the health check HTTP server"""
    port = int(os.getenv('PORT', 10000))  # Render default is 10000
    
    try:
        server = HTTPServer(('0.0.0.0', port), HealthCheckHandler)
        logger.info(f"🌐 Health server started on port {port}")
        server.serve_forever()
    except Exception as e:
        logger.error(f"Failed to start health server: {e}")
        keeper_status['error'] = f"Health server failed: {e}"


def main():
    """Main entry point"""
    logger.info("FlashPeg Arbitrage Keeper Starting...")
    logger.info(f"Python: {sys.version}")
    logger.info(f"Web3 available: {WEB3_AVAILABLE}")
    
    try:
        # Start health check server in background
        health_thread = Thread(target=run_health_server, daemon=True)
        health_thread.start()
        logger.info("✅ Health server thread started")
        
        # Give server time to start
        time.sleep(1)
        
        # Initialize and start keeper
        keeper = ArbitrageKeeper()
        keeper.start()
        
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
        keeper_status['running'] = False
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        keeper_status['error'] = str(e)
        keeper_status['running'] = False
        
        # Keep health server running to report status
        logger.info("Keeping health server running...")
        while True:
            time.sleep(60)


if __name__ == '__main__':
    main()