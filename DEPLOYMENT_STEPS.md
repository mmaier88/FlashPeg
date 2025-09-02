# 📋 Step-by-Step Deployment Recovery

## Current Status: Emergency Deployment Ready

I've debugged the deployment failure using MCP tools and created a recovery strategy.

## Phase 1: Emergency Test (Deploy This Now)

### Files Ready:
- ✅ **app.py** - Ultra-minimal Python app (tested locally)
- ✅ **render.yaml** - Emergency configuration (zero dependencies)
- ✅ **requirements-empty.txt** - No external dependencies

### Deploy Instructions:
1. **Go to Render**: https://dashboard.render.com/
2. **Delete Failed Service** (if exists)
3. **Create New Web Service**:
   - Connect GitHub repo
   - Render will detect `render.yaml` automatically
   - Add environment variables:
     ```
     MAINNET_RPC_URL = [optional for test]
     KEEPER_PRIVATE_KEY = [optional for test]
     ```
4. **Deploy**

### Expected Results:
- ✅ Build: Completes in <30 seconds (no dependencies)
- ✅ Start: App launches immediately 
- ✅ Health: Returns 200 OK at root URL `/`
- ✅ Logs: Shows "Server started successfully on port XXXX"

## Phase 2: Add Complexity (After Emergency Works)

### Step 2A: Add Web3 Dependency
```yaml
buildCommand: pip install web3==6.11.3
startCommand: python app.py
```

### Step 2B: Add Full Keeper
```yaml
buildCommand: pip install -r requirements-render.txt  
startCommand: python keeper_fixed.py
healthCheckPath: /health
```

### Step 2C: Production Ready
```yaml
startCommand: python keeper.py
# Add all environment variables
```

## Phase 3: Debug Specific Failures

### If Emergency Deployment Also Fails:

1. **Check Render Region**: Try `oregon` instead of `auto`
2. **Check Python Version**: Try `3.9` instead of `3.10`
3. **Check Service Type**: Verify it's `web` not `worker`

### If Build Succeeds But Start Fails:

1. **Check Logs** for Python import errors
2. **Verify File Names** (`app.py` exists)
3. **Check Port Binding** (should use `PORT` env var)

### If Health Check Fails:

1. **Verify URL**: Should be `http://your-app.onrender.com/`
2. **Check Response**: Should return JSON
3. **Test Locally**: `curl http://localhost:3002/`

## Common Error Messages & Fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| "Build failed" | Dependencies issue | Use `requirements-empty.txt` |
| "Start command failed" | File not found | Check `app.py` exists |
| "Health check timeout" | Wrong endpoint | Use `healthCheckPath: /` |
| "Port binding failed" | Port issue | Use `generateValue: true` |

## Recovery Commands:

### Test Locally:
```bash
export PORT=3000
python3 app.py
curl http://localhost:3000/
```

### Check File Exists:
```bash
ls -la app.py render.yaml
```

### Verify JSON Response:
```bash
python3 -c "import json; print(json.loads(open('app.py').read()))"
```

## Success Indicators:

- ✅ Render dashboard shows "Live" status
- ✅ Logs show "Server started successfully"  
- ✅ Health URL returns JSON response
- ✅ No error messages in logs

## Next Steps After Success:

1. **Confirm Emergency Works**: Test the deployed URL
2. **Add Web3 Gradually**: One dependency at a time
3. **Add Keeper Logic**: Step by step
4. **Add Environment Variables**: When needed

This approach eliminates variables and identifies exactly what's failing!