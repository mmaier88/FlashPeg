#!/usr/bin/env python3
"""
Bulletproof Python app for Render - handles all edge cases
"""

import os
import sys
import json
import traceback
from http.server import HTTPServer, BaseHTTPRequestHandler

print(f"Python version: {sys.version}")
print(f"Platform: {sys.platform}")
print(f"Current working directory: {os.getcwd()}")

# Get port with multiple fallbacks
PORT = None
for port_source in [os.environ.get('PORT'), '10000', '8080', '5000', '3000']:
    if port_source:
        try:
            PORT = int(port_source)
            print(f"Using port: {PORT} (from {port_source})")
            break
        except (ValueError, TypeError):
            continue

if PORT is None:
    PORT = 10000
    print(f"Fallback to default port: {PORT}")

class RobustHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # Comprehensive environment info
            response = {
                'status': 'success',
                'message': 'FlashPeg is running successfully!',
                'python': {
                    'version': sys.version,
                    'version_info': list(sys.version_info[:3]),
                    'platform': sys.platform,
                    'executable': sys.executable
                },
                'server': {
                    'port': PORT,
                    'host': '0.0.0.0',
                    'working_directory': os.getcwd(),
                    'files_present': {
                        'app.py': os.path.exists('app.py'),
                        'main.py': os.path.exists('main.py'),
                        'render.yaml': os.path.exists('render.yaml')
                    }
                },
                'environment': {
                    'PORT': os.environ.get('PORT'),
                    'PYTHON_VERSION': os.environ.get('PYTHON_VERSION'),
                    'RENDER': os.environ.get('RENDER'),
                    'has_rpc': bool(os.environ.get('MAINNET_RPC_URL')),
                    'has_key': bool(os.environ.get('KEEPER_PRIVATE_KEY'))
                },
                'request': {
                    'path': self.path,
                    'method': self.command,
                    'headers': dict(self.headers) if hasattr(self, 'headers') else {}
                }
            }
            
            self.wfile.write(json.dumps(response, indent=2, default=str).encode())
            print(f"Successfully handled {self.command} {self.path}")
            
        except Exception as e:
            print(f"Error handling request: {e}")
            traceback.print_exc()
            try:
                error_response = {
                    'status': 'error',
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
                self.wfile.write(json.dumps(error_response).encode())
            except:
                self.wfile.write(b'{"status":"critical_error"}')
    
    def do_POST(self):
        # Handle POST requests too
        self.do_GET()
    
    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[HTTP] {format % args}")

def test_basic_functionality():
    """Test that Python basics work"""
    print("Testing basic functionality...")
    
    # Test JSON
    test_data = {"test": "data", "number": 123}
    json_str = json.dumps(test_data)
    parsed = json.loads(json_str)
    assert parsed["test"] == "data"
    print("✅ JSON works")
    
    # Test OS
    cwd = os.getcwd()
    print(f"✅ OS works, CWD: {cwd}")
    
    # Test environment
    env_vars = dict(os.environ)
    print(f"✅ Environment works, {len(env_vars)} variables")
    
    print("All basic tests passed!")

def main():
    print("=" * 60)
    print("FlashPeg Bulletproof Server Starting")
    print("=" * 60)
    
    try:
        # Test basic functionality
        test_basic_functionality()
        
        # Start server
        print(f"\n🚀 Starting HTTP server on 0.0.0.0:{PORT}")
        
        server = HTTPServer(('0.0.0.0', PORT), RobustHandler)
        print(f"✅ Server created successfully")
        print(f"🌐 Server will be available at: http://0.0.0.0:{PORT}")
        print(f"📡 Health check endpoint: http://0.0.0.0:{PORT}/")
        print("📊 Server starting...")
        
        server.serve_forever()
        
    except OSError as e:
        print(f"❌ Server failed to start (Port issue): {e}")
        print(f"   Attempted port: {PORT}")
        print(f"   This usually means the port is in use or permission denied")
        
        # Try alternative ports
        for alt_port in [10001, 8080, 8081, 5000, 3000]:
            try:
                print(f"🔄 Trying alternative port: {alt_port}")
                server = HTTPServer(('0.0.0.0', alt_port), RobustHandler)
                print(f"✅ Server started on alternative port: {alt_port}")
                server.serve_forever()
                break
            except OSError:
                continue
        else:
            print("❌ All ports failed")
            raise
        
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        print("Full traceback:")
        traceback.print_exc()
        
        # Keep process alive for debugging
        print("\n🔍 Keeping process alive for debugging...")
        print("Check Render logs for this output")
        
        import time
        while True:
            print(f"Still alive at {time.time()}")
            time.sleep(60)

if __name__ == '__main__':
    main()