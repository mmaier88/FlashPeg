#!/usr/bin/env python3
"""
Debug script to test all components before Render deployment
"""

import os
import sys
import json
import traceback
from datetime import datetime

def test_environment():
    """Test environment variables"""
    print("=" * 50)
    print("ENVIRONMENT VARIABLE CHECK")
    print("=" * 50)
    
    required = ['MAINNET_RPC_URL', 'KEEPER_PRIVATE_KEY']
    optional = ['ARB_STETH_CONTRACT', 'ARB_DAI_CONTRACT', 'MIN_PROFIT_USD', 'MAX_GAS_PRICE_GWEI', 'POLL_INTERVAL_MS']
    
    issues = []
    
    for var in required:
        value = os.getenv(var)
        if not value:
            print(f"❌ {var}: NOT SET (REQUIRED)")
            issues.append(f"Missing required variable: {var}")
        else:
            # Hide sensitive values
            if 'KEY' in var:
                display_value = value[:10] + "..." if len(value) > 10 else "SET"
            else:
                display_value = value[:50] + "..." if len(value) > 50 else value
            print(f"✅ {var}: {display_value}")
    
    for var in optional:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {value}")
        else:
            print(f"⚠️  {var}: Not set (optional)")
    
    return issues

def test_python_imports():
    """Test required Python imports"""
    print("\n" + "=" * 50)
    print("PYTHON IMPORT CHECK")
    print("=" * 50)
    
    imports_to_test = [
        ('json', 'Standard library'),
        ('os', 'Standard library'), 
        ('time', 'Standard library'),
        ('asyncio', 'Standard library'),
        ('http.server', 'Standard library'),
        ('threading', 'Standard library'),
        ('web3', 'External - pip install web3'),
        ('dotenv', 'External - pip install python-dotenv')
    ]
    
    issues = []
    
    for module, description in imports_to_test:
        try:
            __import__(module)
            print(f"✅ {module}: OK ({description})")
        except ImportError as e:
            print(f"❌ {module}: FAILED - {e}")
            issues.append(f"Missing module: {module}")
    
    return issues

def test_web3_connection():
    """Test Web3 connection"""
    print("\n" + "=" * 50)
    print("WEB3 CONNECTION CHECK")
    print("=" * 50)
    
    rpc_url = os.getenv('MAINNET_RPC_URL')
    if not rpc_url:
        print("❌ Cannot test - MAINNET_RPC_URL not set")
        return ["MAINNET_RPC_URL not set"]
    
    issues = []
    
    try:
        from web3 import Web3
        
        print(f"Connecting to: {rpc_url[:50]}...")
        w3 = Web3(Web3.HTTPProvider(rpc_url))
        
        if w3.is_connected():
            print("✅ Web3 connection: SUCCESS")
            
            # Get latest block
            try:
                block = w3.eth.get_block('latest')
                print(f"✅ Latest block: {block['number']}")
            except Exception as e:
                print(f"⚠️  Could not get block: {e}")
                
        else:
            print("❌ Web3 connection: FAILED")
            issues.append("Cannot connect to RPC")
            
    except Exception as e:
        print(f"❌ Web3 test failed: {e}")
        issues.append(f"Web3 error: {e}")
    
    return issues

def test_wallet():
    """Test wallet/private key"""
    print("\n" + "=" * 50)
    print("WALLET CHECK")
    print("=" * 50)
    
    private_key = os.getenv('KEEPER_PRIVATE_KEY')
    if not private_key:
        print("❌ Cannot test - KEEPER_PRIVATE_KEY not set")
        return ["KEEPER_PRIVATE_KEY not set"]
    
    issues = []
    
    try:
        from web3 import Web3
        
        # Test private key format
        if not private_key.startswith('0x'):
            print("⚠️  Private key doesn't start with 0x")
        
        if len(private_key) != 66:  # 0x + 64 chars
            print(f"⚠️  Private key length: {len(private_key)} (expected 66)")
        
        # Try to create account
        account = Web3().eth.account.from_key(private_key)
        print(f"✅ Wallet address: {account.address}")
        
        # Test connection and balance
        rpc_url = os.getenv('MAINNET_RPC_URL')
        if rpc_url:
            w3 = Web3(Web3.HTTPProvider(rpc_url))
            if w3.is_connected():
                balance = w3.eth.get_balance(account.address)
                balance_eth = w3.from_wei(balance, 'ether')
                print(f"✅ Wallet balance: {balance_eth:.6f} ETH")
                
                if balance_eth < 0.01:
                    print("⚠️  Low wallet balance (< 0.01 ETH)")
                    
    except Exception as e:
        print(f"❌ Wallet test failed: {e}")
        issues.append(f"Wallet error: {e}")
    
    return issues

def test_http_server():
    """Test if we can create HTTP server"""
    print("\n" + "=" * 50)
    print("HTTP SERVER CHECK")
    print("=" * 50)
    
    try:
        from http.server import HTTPServer, BaseHTTPRequestHandler
        import threading
        import time
        
        class TestHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain')
                self.end_headers()
                self.wfile.write(b'OK')
            
            def log_message(self, format, *args):
                pass  # Suppress logs
        
        # Try to start server on a test port
        server = HTTPServer(('localhost', 0), TestHandler)  # 0 = random port
        port = server.server_address[1]
        
        # Start server in thread
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.daemon = True
        server_thread.start()
        
        print(f"✅ HTTP server: Started on port {port}")
        
        # Test request
        import urllib.request
        response = urllib.request.urlopen(f'http://localhost:{port}/')
        if response.read() == b'OK':
            print("✅ HTTP request: SUCCESS")
        
        server.shutdown()
        return []
        
    except Exception as e:
        print(f"❌ HTTP server test failed: {e}")
        return [f"HTTP server error: {e}"]

def main():
    print("FlashPeg Render Deployment Debug")
    print(f"Time: {datetime.now()}")
    print(f"Python: {sys.version}")
    
    # Load .env if exists
    try:
        from dotenv import load_dotenv
        load_dotenv()
        print("✅ Loaded .env file")
    except:
        print("⚠️  No .env file or python-dotenv not installed")
    
    all_issues = []
    
    # Run all tests
    all_issues.extend(test_environment())
    all_issues.extend(test_python_imports()) 
    all_issues.extend(test_web3_connection())
    all_issues.extend(test_wallet())
    all_issues.extend(test_http_server())
    
    # Summary
    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    
    if not all_issues:
        print("🎉 ALL TESTS PASSED! Ready for Render deployment.")
    else:
        print(f"❌ Found {len(all_issues)} issues:")
        for i, issue in enumerate(all_issues, 1):
            print(f"  {i}. {issue}")
        
        print("\nFix these issues before deploying to Render.")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"\nFatal error: {e}")
        traceback.print_exc()