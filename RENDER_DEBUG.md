# 🔧 Render Deployment Debug Guide

## Step 1: Debug Locally First

Run this to check everything before deploying:

```bash
python debug_render.py
```

This will test:
- ✅ Environment variables
- ✅ Python imports
- ✅ Web3 connection
- ✅ Wallet setup
- ✅ HTTP server

Fix any issues it finds before deploying.

## Step 2: Try Minimal Deployment

If the main app fails, start with the absolute minimal version:

### Deploy Minimal App
1. Go to https://dashboard.render.com/
2. Create **Web Service** (not worker!)
3. Connect GitHub repo
4. **IMPORTANT**: Rename `render-minimal.yaml` to `render.yaml` temporarily
5. Set these environment variables:
   ```
   MAINNET_RPC_URL = [optional]
   KEEPER_PRIVATE_KEY = [optional]
   ```
6. Deploy

This minimal app will show you if the basic Python deployment works.

## Step 3: Common Render Issues & Fixes

### Issue: "Build Failed"

**Possible causes:**
1. Missing `requirements.txt`
2. Python version mismatch
3. Network issues during pip install

**Fix:**
```yaml
buildCommand: pip install --upgrade pip && pip install -r requirements.txt --no-cache-dir
```

### Issue: "Service Won't Start"

**Check logs for these errors:**

#### Error: "ModuleNotFoundError"
```
Fix: Add missing module to requirements.txt
```

#### Error: "Port binding failed"
```yaml
# In render.yaml, make sure you have:
envVars:
  - key: PORT
    generateValue: true
```

#### Error: "Permission denied"
```yaml
# Make sure Python files are executable:
startCommand: python keeper.py  # NOT ./keeper.py
```

### Issue: "Health Check Failing"

**For Web Services:**
```yaml
healthCheckPath: /health  # Must return 200 OK
```

**For Workers:**
```yaml
# Remove healthCheckPath - workers don't support it
```

## Step 4: Check Specific Error Messages

### Build Phase Errors

1. **"Could not find a version that satisfies the requirement"**
   ```bash
   # Fix: Update requirements.txt with correct versions
   web3>=6.0.0,<7.0.0
   python-dotenv>=1.0.0
   ```

2. **"Python version not supported"**
   ```yaml
   # Fix: Use supported Python version
   envVars:
     - key: PYTHON_VERSION
       value: "3.10"  # Use 3.10, not 3.11
   ```

### Runtime Errors

1. **"Address already in use"**
   ```python
   # Fix: Use PORT from environment
   PORT = int(os.environ.get('PORT', 10000))
   server = HTTPServer(('0.0.0.0', PORT), Handler)
   ```

2. **"Module not found: web3"**
   ```bash
   # Fix: Ensure requirements.txt is correct and buildCommand runs
   ```

## Step 5: Working Deployment Configurations

### Option A: Web Service (Recommended for Testing)
```yaml
services:
  - type: web
    name: flashpeg-test
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: python minimal_app.py
    healthCheckPath: /health
    envVars:
      - key: PORT
        generateValue: true
```

### Option B: Worker Service (For Production)
```yaml
services:
  - type: worker
    name: flashpeg-keeper
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: python keeper.py
    # NO healthCheckPath for workers!
    envVars:
      - key: PYTHON_VERSION
        value: "3.10"
```

## Step 6: Test Each Component

### Test 1: Basic Python App
```bash
python minimal_app.py
# Should start server on port 3000
# Visit http://localhost:3000/health
```

### Test 2: Web3 Connection
```bash
export MAINNET_RPC_URL="your_rpc_url"
python -c "from web3 import Web3; print('Connected!' if Web3(Web3.HTTPProvider('your_rpc_url')).is_connected() else 'Failed!')"
```

### Test 3: Full Keeper
```bash
export MAINNET_RPC_URL="your_rpc_url"
export KEEPER_PRIVATE_KEY="your_key"
python keeper.py
# Should show "Keeper monitoring started"
```

## Step 7: Render Dashboard Debugging

### Check Deployment Logs
1. Go to your service on Render dashboard
2. Click "Events" tab
3. Look for build/deploy errors

### Check Application Logs
1. Click "Logs" tab
2. Look for Python errors or exceptions
3. Check if app is starting correctly

### Check Environment Variables
1. Click "Environment" tab  
2. Verify all variables are set correctly
3. Make sure KEEPER_PRIVATE_KEY is marked as secret 🔒

## Step 8: Emergency Fixes

### If Everything Fails, Use This Minimal Working Example:

```python
# save as simple_server.py
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'FlashPeg is alive!')
    
    def log_message(self, format, *args):
        print(f"Request: {format % args}")

PORT = int(os.environ.get('PORT', 10000))
print(f"Starting on port {PORT}")
HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
```

Deploy with:
```yaml
services:
  - type: web
    name: flashpeg-emergency
    runtime: python
    startCommand: python simple_server.py
```

## Need More Help?

Run the debug script and paste the output:
```bash
python debug_render.py
```

This will show exactly what's wrong with your setup!