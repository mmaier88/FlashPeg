# 🚀 FlashPeg One-Click Deployment Guide

Deploy your FlashPeg arbitrage bot to Render in minutes!

## Quick Deploy Options

### Option 1: One-Click Deploy Button (Recommended)
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/mmaier88/FlashPeg)

Click the button above to deploy instantly to Render using our pre-configured `app.json`.

### Option 2: Automated Script
Run our automated deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Install Render CLI if needed
- Authenticate with your Render account  
- Deploy FlashPeg automatically
- Provide your live app URL

### Option 3: Manual Render Dashboard
1. Fork this repository to your GitHub
2. Go to [Render Dashboard](https://dashboard.render.com/)
3. Click "New" → "Web Service"
4. Connect your forked repository
5. Use these settings:
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements-flask.txt`
   - **Start Command**: `gunicorn wsgi:app`
   - **Health Check**: `/health`

## After Deployment

### 1. Verify Deployment
Run the verification script:
```bash
chmod +x verify-deployment.sh
./verify-deployment.sh https://your-app.onrender.com
```

### 2. Configure Environment Variables
Add these in your Render dashboard under Environment:

**Required for Trading:**
- `MAINNET_RPC_URL` - Your Ethereum RPC URL (Alchemy/Infura)
- `KEEPER_PRIVATE_KEY` - Private key for keeper wallet

**Contract Addresses (after deployment):**
- `ARB_STETH_CONTRACT` - Deployed stETH arbitrage contract
- `ARB_DAI_CONTRACT` - Deployed DAI arbitrage contract

**Optional Settings:**
- `MIN_PROFIT_USD` - Minimum profit threshold (default: 100)
- `MAX_GAS_PRICE_GWEI` - Max gas price (default: 50)

### 3. Deploy Smart Contracts
```bash
# Install dependencies
npm install

# Deploy contracts (testnet first!)
npx hardhat deploy --network goerli
npx hardhat deploy --network mainnet
```

### 4. Monitor Your Bot
- **Live App**: `https://your-app.onrender.com`
- **Health Check**: `https://your-app.onrender.com/health`
- **Render Logs**: [Dashboard](https://dashboard.render.com/)

## Troubleshooting

### Deployment Issues
- Use `verify-deployment.sh` to diagnose problems
- Check Render logs for detailed errors
- Ensure all required files are in repository

### Runtime Issues
- Verify RPC URL is working
- Check private key has sufficient ETH for gas
- Monitor gas prices vs MAX_GAS_PRICE_GWEI

### Performance
- App cold starts may take 30-60 seconds
- Consider upgrading to paid Render plan for faster startups
- Monitor response times with verification script

## Support

- 📖 **Documentation**: Check README.md
- 🔧 **Issues**: Open GitHub issues
- 📊 **Monitoring**: Use Render dashboard logs
- 💡 **Tips**: Run verification script regularly

---

**Ready to start arbitraging?** Click the Deploy to Render button above! 🚀