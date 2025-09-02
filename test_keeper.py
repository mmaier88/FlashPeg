#!/usr/bin/env python3
"""Test script to verify keeper works locally"""

import os
import time
import requests
from dotenv import load_dotenv

# Load test environment
load_dotenv('.env.test')

# Set test environment variables if not present
if not os.getenv('MAINNET_RPC_URL'):
    os.environ['MAINNET_RPC_URL'] = 'https://eth-mainnet.g.alchemy.com/v2/demo'
if not os.getenv('KEEPER_PRIVATE_KEY'):
    # Test private key (DO NOT USE IN PRODUCTION)
    os.environ['KEEPER_PRIVATE_KEY'] = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

print("Testing keeper locally...")
print(f"RPC URL: {os.getenv('MAINNET_RPC_URL')[:50]}...")

# Import and start keeper
try:
    from keeper import ArbitrageKeeper, run_health_server
    from threading import Thread
    
    # Start health server
    health_thread = Thread(target=run_health_server, daemon=True)
    health_thread.start()
    
    # Wait for server to start
    time.sleep(2)
    
    # Test health endpoint
    response = requests.get('http://localhost:3000/health')
    print(f"Health check status: {response.status_code}")
    print(f"Response: {response.json()}")
    
    if response.status_code == 200:
        print("✅ Keeper test successful!")
    else:
        print("❌ Health check failed")
        
except Exception as e:
    print(f"❌ Test failed: {e}")
    import traceback
    traceback.print_exc()