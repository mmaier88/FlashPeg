# Setting Up Secrets for Render Deployment

## Quick Start

1. Copy `.env.render` to `.env.local` and fill in your values
2. Upload to Render's environment variables section
3. Deploy!

## Step-by-Step Guide

### 1. Get an Ethereum RPC URL

Choose one of these providers:

#### Alchemy (Recommended)
1. Sign up at https://www.alchemy.com/
2. Create new app → Select "Ethereum" → "Mainnet"
3. Copy the HTTPS URL
4. Format: `https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY_HERE`

#### Infura
1. Sign up at https://infura.io/
2. Create new project
3. Copy the Mainnet endpoint
4. Format: `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`

### 2. Create Keeper Wallet

**Option A: MetaMask**
1. Install MetaMask
2. Create new wallet (don't use your main wallet!)
3. Go to Settings → Security & Privacy → Show Private Keys
4. Copy the private key (starts with 0x)

**Option B: Command Line**
```bash
# Using ethers.js
node -e "console.log(require('ethers').Wallet.createRandom().privateKey)"
```

**Important**: 
- This wallet needs ETH for gas (start with 0.5 ETH)
- Only fund with what you're willing to risk
- Save the private key securely

### 3. Deploy Smart Contracts

```bash
# Install dependencies
npm install
forge install

# Set environment for deployment
export MAINNET_RPC_URL="your_rpc_url_here"
export DEPLOYER_PRIVATE_KEY="your_deployer_private_key"

# Deploy contracts
forge script scripts/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify

# Note the output addresses:
# ArbStETH deployed at: 0x...
# ArbDaiPeg deployed at: 0x...
```

### 4. Fill in the .env File

```env
# Your actual values:
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/abc123yourkey
KEEPER_PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
ARB_STETH_CONTRACT=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1
ARB_DAI_CONTRACT=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
```

### 5. Upload to Render

#### Method 1: Dashboard UI
1. Go to your service on Render
2. Click "Environment" tab
3. Add each variable one by one
4. Mark `KEEPER_PRIVATE_KEY` as secret

#### Method 2: Render CLI
```bash
# Install Render CLI
brew tap render-oss/render
brew install render

# Set environment variables
render env:set MAINNET_RPC_URL="your_value" --service flashpeg-keeper
render env:set KEEPER_PRIVATE_KEY="your_value" --secret --service flashpeg-keeper
render env:set ARB_STETH_CONTRACT="your_value" --service flashpeg-keeper
render env:set ARB_DAI_CONTRACT="your_value" --service flashpeg-keeper
```

## Testing Your Setup

### 1. Test RPC Connection
```javascript
// test-rpc.js
const { ethers } = require('ethers');
const provider = new ethers.JsonRpcProvider('YOUR_RPC_URL');
provider.getBlockNumber().then(console.log);
```

### 2. Test Keeper Wallet
```javascript
// test-wallet.js
const { ethers } = require('ethers');
const wallet = new ethers.Wallet('YOUR_PRIVATE_KEY');
console.log('Address:', wallet.address);
```

### 3. Verify Contract Deployment
Visit Etherscan and search for your contract addresses to verify they're deployed.

## Security Best Practices

### DO ✅
- Create a new wallet specifically for the keeper
- Use Render's secret environment variables
- Start with small amounts of ETH
- Monitor the wallet balance regularly
- Set up alerts for low balance

### DON'T ❌
- Use your main wallet's private key
- Commit .env files with real values
- Share your private key with anyone
- Store more ETH than needed in keeper wallet

## Troubleshooting

### "Invalid RPC URL"
- Check the URL format is correct
- Ensure you've signed up and the API key is active
- Test with curl: `curl YOUR_RPC_URL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`

### "Insufficient funds"
- Check keeper wallet balance
- Ensure wallet has ETH for gas
- Send ETH to the keeper address

### "Contract not found"
- Verify deployment was successful
- Check you're using the correct network (mainnet vs testnet)
- Confirm addresses match deployment output

## Example Working Configuration

Here's a complete example with dummy values:

```env
# Working example (replace with your values)
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/PZxcM3kY9A5jW8nR4tQ2uL6vB8mX0
KEEPER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ARB_STETH_CONTRACT=0x1234567890123456789012345678901234567890
ARB_DAI_CONTRACT=0x0987654321098765432109876543210987654321
MIN_PROFIT_USD=100
MAX_GAS_PRICE_GWEI=50
POLL_INTERVAL_MS=5000
```

## Support Resources

- **Alchemy Discord**: https://discord.gg/alchemy
- **Infura Community**: https://community.infura.io/
- **Render Discord**: https://discord.gg/render
- **Etherscan**: https://etherscan.io/