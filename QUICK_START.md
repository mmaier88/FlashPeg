# 🚀 Quick Start Guide - Deploy Everything in 5 Minutes

## Prerequisites
- Mac/Linux terminal (Windows users: use WSL)
- GitHub account
- Render account (free at https://render.com)

## One-Command Setup

```bash
# Make script executable and run
chmod +x scripts/setup-all.sh
./scripts/setup-all.sh
```

This script will:
1. ✅ Generate wallets automatically
2. ✅ Help you get an RPC URL
3. ✅ Deploy smart contracts
4. ✅ Prepare everything for Render

## What the Script Does

### Step 1: Generate Wallets
- Creates 2 new wallets (Deployer + Keeper)
- Saves private keys to `.env.generated`
- **IMPORTANT**: Save these keys somewhere safe!

### Step 2: Get RPC URL
You'll be prompted to either:
- Enter your RPC URL (from Alchemy/Infura)
- Or type 'skip' to use testnet

**Get Free RPC URL:**
1. Go to https://www.alchemy.com/
2. Sign up (free)
3. Create new app → Ethereum → Mainnet
4. Copy the HTTPS URL

### Step 3: Fund Wallets
The script will show you:
- How much ETH you need
- Your wallet addresses
- Where to get testnet ETH (if using testnet)

**Testnet (Recommended for Testing):**
- Get free Goerli ETH: https://goerlifaucet.com/
- Need: 0.2 ETH total (0.1 for each wallet)

**Mainnet (Real Money):**
- Need: 0.8 ETH total
- 0.3 ETH for deployer (contract deployment)
- 0.5 ETH for keeper (gas for trades)

### Step 4: Automatic Contract Deployment
Script deploys both contracts and saves addresses

### Step 5: Deploy to Render

After script completes:

1. **Go to Render Dashboard:**
   https://dashboard.render.com/

2. **Create New Background Worker:**
   - Click "New +" → "Background Worker"
   - Connect GitHub: `https://github.com/mmaier88/FlashPeg`
   - Name: `flashpeg-keeper`

3. **Add Environment Variables:**
   The script shows you exactly what to add:
   ```
   MAINNET_RPC_URL = [your-rpc-url]
   KEEPER_PRIVATE_KEY = [your-keeper-key] 🔒 CLICK LOCK ICON!
   ARB_STETH_CONTRACT = [deployed-address]
   ARB_DAI_CONTRACT = [deployed-address]
   ```

4. **Deploy:**
   Click "Create Background Worker"

## 📋 Manual Setup (If Script Fails)

### 1. Generate Wallets Manually
```bash
node scripts/generate-wallet.js deployer
node scripts/generate-wallet.js keeper
```

### 2. Create .env File
```bash
cat > .env << EOF
MAINNET_RPC_URL=your_rpc_url_here
DEPLOYER_PRIVATE_KEY=your_deployer_key
KEEPER_PRIVATE_KEY=your_keeper_key
EOF
```

### 3. Deploy Contracts
```bash
# Install dependencies
npm install
forge install

# Deploy
forge script scripts/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast
```

### 4. Note Contract Addresses
Look for lines like:
```
ArbStETH deployed at: 0x...
ArbDaiPeg deployed at: 0x...
```

## 🧪 Testing First? Use Goerli

1. When script asks for RPC, type: `skip`
2. Get free Goerli ETH: https://goerlifaucet.com/
3. Everything else works the same!

## ⚠️ Security Checklist

- [ ] Saved private keys securely (password manager)
- [ ] Using NEW wallets (not your main wallet)
- [ ] Marked KEEPER_PRIVATE_KEY as secret in Render (lock icon 🔒)
- [ ] Only funded keeper with necessary ETH
- [ ] Didn't commit .env files to GitHub

## 📊 Costs

**Testnet (Goerli):**
- Everything is free!
- Use for testing

**Mainnet:**
- Contract deployment: ~0.2-0.3 ETH ($400-600)
- Keeper gas fund: 0.5 ETH ($1000)
- Render hosting: $7/month
- RPC provider: $0-50/month

## 🆘 Troubleshooting

### "Command not found: forge"
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### "Insufficient funds"
- Check wallet addresses shown by script
- Send ETH to those addresses
- Press Enter to continue

### "RPC error"
- Make sure your RPC URL is correct
- Try Alchemy instead of Infura
- Check if you have API credits

### Script Permissions Error
```bash
chmod +x scripts/setup-all.sh
chmod +x scripts/generate-wallet.js
```

## 📞 Need Help?

1. Check if contracts deployed:
   - Look in `deployments/` folder
   - Check on Etherscan

2. Verify Render deployment:
   - Check logs in Render dashboard
   - Look for "Keeper started" message

3. Monitor bot:
   - Render dashboard → Logs
   - Should show "Checking for opportunities..."

## 🎯 Success Indicators

✅ Script shows "Setup Complete!"
✅ You see contract addresses
✅ `.env.render.ready` file created
✅ Render shows "Deploy succeeded"
✅ Logs show "Arbitrage Keeper started"

## 🔄 Start Over

If something goes wrong:
```bash
# Clean up
rm -f .env.generated .env.render.ready
rm -rf deployments/

# Run setup again
./scripts/setup-all.sh
```

---

**Ready to make money with arbitrage? Run the setup script now!** 🚀