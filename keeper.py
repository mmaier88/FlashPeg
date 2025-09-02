#!/usr/bin/env python3
"""
FlashPeg Arbitrage Keeper Bot - Python Version
Monitors and executes arbitrage opportunities for stETH/ETH and DAI peg
"""

import os
import sys
import time
import json
import logging
import asyncio
from datetime import datetime
from typing import Dict, Any, Optional
from threading import Thread
from http.server import HTTPServer, BaseHTTPRequestHandler

from web3 import Web3
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('flashpeg-keeper')

# Global status for health checks
keeper_status = {
    'running': False,
    'last_check': None,
    'successful_arbs': 0,
    'failed_arbs': 0,
    'wallet_address': None,
    'error': None
}


class HealthCheckHandler(BaseHTTPRequestHandler):
    """Simple HTTP handler for health checks"""
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200 if keeper_status['running'] else 503)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'healthy' if keeper_status['running'] else 'unhealthy',
                'timestamp': datetime.now().isoformat(),
                **keeper_status
            }
            self.wfile.write(json.dumps(response).encode())
        
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response = {
                'name': 'FlashPeg Arbitrage Keeper',
                'version': '1.0.0',
                'status': 'running' if keeper_status['running'] else 'initializing'
            }
            self.wfile.write(json.dumps(response).encode())
        
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Override to suppress request logs"""
        pass


class ArbitrageKeeper:
    """Main keeper bot class"""
    
    def __init__(self):
        # Get environment variables
        self.rpc_url = os.getenv('MAINNET_RPC_URL')
        self.private_key = os.getenv('KEEPER_PRIVATE_KEY')
        self.steth_contract = os.getenv('ARB_STETH_CONTRACT')
        self.dai_contract = os.getenv('ARB_DAI_CONTRACT')
        
        # Configuration
        self.min_profit_usd = int(os.getenv('MIN_PROFIT_USD', '100'))
        self.max_gas_gwei = int(os.getenv('MAX_GAS_PRICE_GWEI', '50'))
        self.poll_interval = int(os.getenv('POLL_INTERVAL_MS', '5000')) / 1000
        
        # Validate required environment variables
        if not self.rpc_url:
            raise ValueError("MAINNET_RPC_URL is required")
        if not self.private_key:
            raise ValueError("KEEPER_PRIVATE_KEY is required")
        
        # Initialize Web3
        self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
        if not self.w3.is_connected():
            raise ConnectionError(f"Failed to connect to {self.rpc_url}")
        
        # Set up account
        try:
            self.account = self.w3.eth.account.from_key(self.private_key)
            self.wallet_address = self.account.address
            keeper_status['wallet_address'] = self.wallet_address
            logger.info(f"Keeper initialized with wallet: {self.wallet_address}")
        except Exception as e:
            raise ValueError(f"Invalid private key: {e}")
        
        # Get wallet balance
        balance = self.w3.eth.get_balance(self.wallet_address)
        balance_eth = self.w3.from_wei(balance, 'ether')
        logger.info(f"Wallet balance: {balance_eth:.4f} ETH")
        
        # Log contract addresses
        if self.steth_contract:
            logger.info(f"stETH Arbitrage Contract: {self.steth_contract}")
        else:
            logger.warning("stETH contract not configured")
            
        if self.dai_contract:
            logger.info(f"DAI Peg Arbitrage Contract: {self.dai_contract}")
        else:
            logger.warning("DAI contract not configured")
    
    async def check_steth_opportunity(self) -> Optional[Dict[str, Any]]:
        """Check for stETH/ETH arbitrage opportunities"""
        try:
            # Get current block
            block = self.w3.eth.get_block('latest')
            logger.debug(f"Checking stETH opportunity at block {block['number']}")
            
            # In production, would check actual price differences here
            # For now, just return no opportunity
            return None
            
        except Exception as e:
            logger.error(f"Error checking stETH opportunity: {e}")
            return None
    
    async def check_dai_opportunity(self) -> Optional[Dict[str, Any]]:
        """Check for DAI peg arbitrage opportunities"""
        try:
            # Get current block
            block = self.w3.eth.get_block('latest')
            logger.debug(f"Checking DAI opportunity at block {block['number']}")
            
            # In production, would check actual price differences here
            # For now, just return no opportunity
            return None
            
        except Exception as e:
            logger.error(f"Error checking DAI opportunity: {e}")
            return None
    
    async def execute_arbitrage(self, opportunity: Dict[str, Any]) -> bool:
        """Execute an arbitrage opportunity"""
        try:
            logger.info(f"Executing arbitrage: {opportunity}")
            
            # Check gas price
            gas_price = self.w3.eth.gas_price
            gas_price_gwei = self.w3.from_wei(gas_price, 'gwei')
            
            if gas_price_gwei > self.max_gas_gwei:
                logger.warning(f"Gas price too high: {gas_price_gwei:.2f} gwei")
                return False
            
            # In production, would build and send transaction here
            # For now, just simulate success
            keeper_status['successful_arbs'] += 1
            return True
            
        except Exception as e:
            logger.error(f"Error executing arbitrage: {e}")
            keeper_status['failed_arbs'] += 1
            return False
    
    async def monitor_loop(self):
        """Main monitoring loop"""
        keeper_status['running'] = True
        logger.info("🚀 Keeper monitoring started")
        
        while keeper_status['running']:
            try:
                keeper_status['last_check'] = datetime.now().isoformat()
                
                # Check both opportunities
                tasks = []
                if self.steth_contract:
                    tasks.append(self.check_steth_opportunity())
                if self.dai_contract:
                    tasks.append(self.check_dai_opportunity())
                
                if tasks:
                    opportunities = await asyncio.gather(*tasks)
                    
                    # Execute profitable opportunities
                    for opp in opportunities:
                        if opp and opp.get('profitable'):
                            await self.execute_arbitrage(opp)
                else:
                    logger.info("No contracts configured, waiting...")
                
                # Log status periodically
                if keeper_status['successful_arbs'] > 0 or keeper_status['failed_arbs'] > 0:
                    logger.info(f"Status - Success: {keeper_status['successful_arbs']}, Failed: {keeper_status['failed_arbs']}")
                
            except Exception as e:
                logger.error(f"Error in monitor loop: {e}")
                keeper_status['error'] = str(e)
            
            # Wait before next check
            await asyncio.sleep(self.poll_interval)
    
    def start(self):
        """Start the keeper"""
        asyncio.run(self.monitor_loop())


def run_health_server():
    """Run the health check HTTP server"""
    port = int(os.getenv('PORT', 3000))
    server = HTTPServer(('0.0.0.0', port), HealthCheckHandler)
    logger.info(f"Health check server listening on port {port}")
    server.serve_forever()


def main():
    """Main entry point"""
    try:
        # Start health check server in background thread
        health_thread = Thread(target=run_health_server, daemon=True)
        health_thread.start()
        
        # Initialize and start keeper
        keeper = ArbitrageKeeper()
        keeper.start()
        
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        keeper_status['running'] = False
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        keeper_status['error'] = str(e)
        keeper_status['running'] = False
        
        # Keep health server running to report unhealthy status
        while True:
            time.sleep(60)


if __name__ == '__main__':
    main()