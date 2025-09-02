# Deployment Guide for Render

## Prerequisites

1. **Deploy Smart Contracts First**
   - Deploy the arbitrage contracts to mainnet using the deployment scripts
   - Note down the deployed contract addresses

2. **Required Environment Variables**
   - `MAINNET_RPC_URL`: Your Ethereum mainnet RPC endpoint (Infura, Alchemy, etc.)
   - `KEEPER_PRIVATE_KEY`: Private key for the keeper wallet (with ETH for gas)
   - `ARB_STETH_CONTRACT`: Deployed ArbStETH contract address
   - `ARB_DAI_CONTRACT`: Deployed ArbDaiPeg contract address

## Deployment Steps

### 1. Deploy Smart Contracts

```bash
# Install dependencies
npm install
forge install

# Deploy to mainnet
forge script scripts/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify

# Note the deployed contract addresses from the output
```

### 2. Deploy to Render

#### Option A: Using Render Dashboard

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Background Worker"
3. Connect your GitHub account
4. Select the `FlashPeg` repository
5. Configure the service:
   - **Name**: flashpeg-keeper
   - **Environment**: Node
   - **Build Command**: `npm install && npm run build:keeper`
   - **Start Command**: `npm run keeper:prod`
6. Add environment variables:
   - `MAINNET_RPC_URL`: Your RPC URL
   - `KEEPER_PRIVATE_KEY`: Your keeper wallet private key (mark as secret)
   - `ARB_STETH_CONTRACT`: Your deployed stETH arbitrage contract
   - `ARB_DAI_CONTRACT`: Your deployed DAI arbitrage contract
   - `MIN_PROFIT_USD`: 100 (or your preference)
   - `MAX_GAS_PRICE_GWEI`: 50 (or your preference)
   - `POLL_INTERVAL_MS`: 5000 (or your preference)
7. Click "Create Background Worker"

#### Option B: Using render.yaml (Blueprint)

1. Fork or use this repository
2. Go to [Render Dashboard](https://dashboard.render.com/)
3. Click "New +" → "Blueprint"
4. Connect the `FlashPeg` repository
5. Choose deployment type:
   - **render.yaml**: Background worker (no health checks, lower cost)
   - **render-web.yaml**: Web service (with health checks, slightly higher cost)
6. Configure the required environment variables
7. Deploy

**Note**: Workers don't support health check paths. Use `render-web.yaml` if you need HTTP health monitoring.

### 3. Monitor Deployment

1. Check the Render dashboard for deployment status
2. View logs to ensure the keeper is running properly
3. Monitor the health endpoint: `https://your-service.onrender.com/health`

## Post-Deployment

### Monitoring

- **Health Check**: `https://your-service.onrender.com/health`
- **Metrics**: `https://your-service.onrender.com/metrics`
- **Logs**: Available in Render dashboard

### Updating Configuration

To update environment variables:
1. Go to your service in Render dashboard
2. Navigate to "Environment" tab
3. Update variables as needed
4. Service will automatically redeploy

### Scaling

For production use:
1. Consider upgrading to a paid Render plan for better performance
2. Use multiple keeper instances in different regions
3. Implement redundancy with multiple RPC providers

## Security Considerations

1. **Never commit private keys** to the repository
2. Use Render's secret environment variables for sensitive data
3. Regularly rotate keeper wallet private keys
4. Monitor wallet balance for gas
5. Set up alerts for failed transactions

## Troubleshooting

### Common Issues

1. **"Missing required environment variables"**
   - Ensure all required env vars are set in Render dashboard
   
2. **"Insufficient funds for gas"**
   - Add ETH to your keeper wallet
   
3. **"RPC rate limit exceeded"**
   - Upgrade your RPC plan or increase POLL_INTERVAL_MS
   
4. **Health check failing**
   - Check logs for initialization errors
   - Verify contract addresses are correct
   - Ensure RPC URL is valid

## Maintenance

### Regular Tasks

1. Monitor keeper wallet balance
2. Check logs for errors
3. Update gas price limits based on network conditions
4. Review and update minimum profit thresholds
5. Upgrade dependencies regularly

### Updating the Bot

```bash
# Make changes locally
git add .
git commit -m "Update keeper logic"
git push origin main

# Render will automatically redeploy
```

## Cost Considerations

- **Render Costs**: ~$7-25/month for worker
- **RPC Costs**: Varies by provider ($50-500/month)
- **Gas Costs**: Depends on arbitrage frequency
- **Profit**: Should exceed operational costs

## Support

For issues:
1. Check Render logs
2. Review health endpoint response
3. Verify environment variables
4. Check smart contract state on Etherscan