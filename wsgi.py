#!/usr/bin/env python3
"""
Flask app - most reliable Python deployment for Render
"""

import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'status': 'success',
        'message': 'FlashPeg Flask App Running!',
        'python_version': os.sys.version,
        'environment': {
            'PORT': os.environ.get('PORT'),
            'PYTHON_VERSION': os.environ.get('PYTHON_VERSION'),
            'RENDER': os.environ.get('RENDER', 'false'),
            'has_rpc': bool(os.environ.get('MAINNET_RPC_URL')),
            'has_key': bool(os.environ.get('KEEPER_PRIVATE_KEY'))
        }
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/ping')
def ping():
    return 'pong'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)