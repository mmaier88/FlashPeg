#!/usr/bin/env python3
"""
Minimal working app for Render debugging
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
        
        if self.path == '/health':
            response = {'status': 'healthy', 'message': 'App is running!'}
        else:
            response = {
                'name': 'FlashPeg Minimal',
                'version': '1.0.0',
                'env_vars': {
                    'PORT': os.environ.get('PORT'),
                    'PYTHON_VERSION': os.environ.get('PYTHON_VERSION'),
                    'RPC_SET': bool(os.environ.get('MAINNET_RPC_URL')),
                    'KEY_SET': bool(os.environ.get('KEEPER_PRIVATE_KEY'))
                }
            }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def log_message(self, format, *args):
        # Print logs so Render can see them
        print(f"Request: {format % args}")

if __name__ == '__main__':
    print(f"Starting minimal app on port {PORT}")
    print(f"Environment check:")
    print(f"- PORT: {PORT}")
    print(f"- PYTHON_VERSION: {os.environ.get('PYTHON_VERSION', 'not set')}")
    print(f"- MAINNET_RPC_URL: {'SET' if os.environ.get('MAINNET_RPC_URL') else 'NOT SET'}")
    print(f"- KEEPER_PRIVATE_KEY: {'SET' if os.environ.get('KEEPER_PRIVATE_KEY') else 'NOT SET'}")
    
    server = HTTPServer(('0.0.0.0', PORT), Handler)
    print(f"Server listening on http://0.0.0.0:{PORT}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()