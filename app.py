#!/usr/bin/env python3
"""
Ultra-minimal Python app for Render - guaranteed to work
Zero dependencies, basic HTTP server only
"""

import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = int(os.environ.get('PORT', 10000))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        response = {
            'status': 'success',
            'message': 'FlashPeg is running!',
            'port': PORT,
            'env': {
                'PYTHON_VERSION': os.environ.get('PYTHON_VERSION'),
                'PORT': os.environ.get('PORT'),
                'has_rpc': bool(os.environ.get('MAINNET_RPC_URL')),
                'has_key': bool(os.environ.get('KEEPER_PRIVATE_KEY'))
            }
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def log_message(self, format, *args):
        print(f"[{self.__class__.__name__}] {format % args}")

def main():
    print(f"Starting ultra-minimal app on port {PORT}")
    print(f"Environment check:")
    for key in ['PORT', 'PYTHON_VERSION', 'MAINNET_RPC_URL', 'KEEPER_PRIVATE_KEY']:
        value = os.environ.get(key)
        if key in ['KEEPER_PRIVATE_KEY'] and value:
            print(f"  {key}: SET (hidden)")
        else:
            print(f"  {key}: {value}")
    
    try:
        server = HTTPServer(('0.0.0.0', PORT), Handler)
        print(f"✅ Server started successfully on http://0.0.0.0:{PORT}")
        server.serve_forever()
    except Exception as e:
        print(f"❌ Server failed to start: {e}")
        raise

if __name__ == '__main__':
    main()