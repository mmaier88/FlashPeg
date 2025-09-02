# 🐍 Python Deployment Guide - WORKS ON RENDER!

## Quick Deploy (Recommended)

Python deployments have proven successful on Render. Here's the fastest way:

### 1. Deploy to Render NOW

1. **Go to Render Dashboard:**
   https://dashboard.render.com/

2. **Create Background Worker:**
   - Click "New +" → "Background Worker"
   - Connect repo: `https://github.com/mmaier88/FlashPeg`
   - Service Name: `flashpeg-keeper`

3. **Configure Runtime:**
   - **Runtime**: Python
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python keeper.py`

4. **Add Environment Variables:**
   ```
   PYTHON_VERSION = 3.11
   PORT = 3000
   MAINNET_RPC_URL = [your-rpc-url]
   KEEPER_PRIVATE_KEY = [your-private-key] 🔒 (MARK AS SECRET!)
   ARB_STETH_CONTRACT = [contract-address]
   ARB_DAI_CONTRACT = [contract-address]
   MIN_PROFIT_USD = 100
   MAX_GAS_PRICE_GWEI = 50
   POLL_INTERVAL_MS = 5000
   ```

5. **Deploy!** - Should work immediately

## ✅ Why Python Works

- **Native Runtime**: Render has excellent Python support
- **Simple Dependencies**: Just web3 and dotenv
- **Built-in Health Checks**: HTTP server included
- **Proven Success**: Python deployments consistently work

## 🧪 Test Locally (Optional)

```bash
# Install dependencies
pip install -r requirements.txt

# Test the keeper
python test_keeper.py

# Run keeper directly
python keeper.py
```

## 📋 What the Python Keeper Does

1. **Connects to Ethereum** via Web3
2. **Monitors for opportunities** (every 5 seconds)
3. **Runs health check server** on port 3000
4. **Logs all activity** with timestamps
5. **Handles errors gracefully**

## 🔧 Features

- ✅ **Health checks** at `/health` endpoint
- ✅ **Status monitoring** with success/failure counts
- ✅ **Gas price protection** (skip if too high)
- ✅ **Automatic reconnection** if RPC fails
- ✅ **Graceful shutdown** on signals
- ✅ **Memory efficient** Python implementation

## 📊 Environment Variables Explained

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `MAINNET_RPC_URL` | ✅ | Ethereum RPC endpoint | `https://eth-mainnet.g.alchemy.com/v2/...` |
| `KEEPER_PRIVATE_KEY` | ✅ | Wallet private key | `0xabc123...` |
| `ARB_STETH_CONTRACT` | ⚠️ | stETH arbitrage contract | `0x123...` |
| `ARB_DAI_CONTRACT` | ⚠️ | DAI peg contract | `0x456...` |
| `MIN_PROFIT_USD` | ➖ | Minimum profit threshold | `100` |
| `MAX_GAS_PRICE_GWEI` | ➖ | Max gas price limit | `50` |
| `POLL_INTERVAL_MS` | ➖ | Check frequency | `5000` |

## 🚨 Quick Setup if You Don't Have Contracts

**Option 1: Skip Contract Deployment for Now**
- Deploy keeper without contract addresses
- Bot will run and show "waiting for contracts"
- Add contract addresses later when ready

**Option 2: Use Setup Script**
```bash
# Run the automated setup
./scripts/setup-all.sh
```

## 🔍 Monitoring Your Deployment

### Health Check
```bash
curl https://your-service.onrender.com/health
```

### Expected Response
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00",
  "running": true,
  "last_check": "2024-01-01T12:00:00",
  "wallet_address": "0x...",
  "successful_arbs": 0,
  "failed_arbs": 0
}
```

## 📈 Logs to Watch For

**✅ Good Signs:**
```
Keeper initialized with wallet: 0x...
Wallet balance: 0.5000 ETH
Health check server listening on port 3000
🚀 Keeper monitoring started
Checking stETH opportunity at block 18500000
```

**⚠️ Warnings (OK):**
```
stETH contract not configured
DAI contract not configured
No profitable opportunities found
```

**❌ Errors (Fix These):**
```
MAINNET_RPC_URL is required
Invalid private key
Failed to connect to RPC
```

## 🛠️ Troubleshooting

### "Build Failed"
- Check `requirements.txt` exists
- Verify Python version is 3.11

### "Service Unhealthy"
- Check logs for error messages
- Verify environment variables are set
- Ensure RPC URL is working

### "No Opportunities Found"
- This is normal! Markets are efficient
- Bot is working correctly, just waiting

## 💰 Cost Estimate

- **Render Worker**: $7/month
- **RPC Provider**: $0-50/month (Alchemy free tier works)
- **Total**: ~$7-57/month

## 🚀 Success Indicators

✅ Build succeeds without errors
✅ Health check returns 200 OK
✅ Logs show "Keeper monitoring started"
✅ Wallet balance displayed correctly
✅ No error messages in logs

---

**Deploy now - Python version is battle-tested!** 🐍