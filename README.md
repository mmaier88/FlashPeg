# FlashPeg Arbitrage Bot

A sophisticated flash loan arbitrage bot for capturing price discrepancies in stETH/ETH and DAI/USDC peg deviations.

## Overview

This bot monitors and executes arbitrage opportunities in two main markets:
1. **stETH/ETH Basis Trading**: Exploits price differences between liquid staking derivatives and ETH
2. **DAI Peg Arbitrage**: Captures profit when DAI deviates from its $1 peg

## Features

- 🚀 Zero-capital arbitrage using flash loans
- 💰 Automated opportunity detection and execution
- ⛽ Gas-optimized smart contracts
- 📊 Real-time price monitoring from multiple DEXs
- 🔒 Secure keeper-based architecture
- 📈 Comprehensive logging and monitoring

## Architecture

```
FlashPeg/
├── contracts/              # Solidity smart contracts
│   ├── ArbStETH.sol       # stETH/ETH arbitrage logic
│   ├── ArbDaiPeg.sol      # DAI peg arbitrage logic
│   └── interfaces/        # External contract interfaces
├── keeper/                # Off-chain keeper bot
│   ├── src/
│   │   ├── strategies/    # Arbitrage strategies
│   │   ├── utils/         # Monitoring and utilities
│   │   └── config/        # Configuration
│   └── index.ts           # Main keeper entry point
├── scripts/               # Deployment and verification
└── test/                  # Foundry test suite
```

## Installation

### Prerequisites
- Node.js v18+
- Foundry
- Git

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/flashpeg
cd flashpeg
```

2. Install dependencies:
```bash
npm install
forge install
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your settings
```

## Configuration

### Required Environment Variables

```env
# RPC URLs
MAINNET_RPC_URL=your_rpc_url

# Private Keys (NEVER commit!)
DEPLOYER_PRIVATE_KEY=0x...
KEEPER_PRIVATE_KEY=0x...

# Keeper Settings
MIN_PROFIT_USD=100
MAX_GAS_PRICE_GWEI=50
POLL_INTERVAL_MS=5000
```

## Deployment

### Deploy to Mainnet

```bash
# Deploy contracts
forge script scripts/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast

# Verify on Etherscan
./scripts/verify.sh
```

### Deploy to Testnet

```bash
forge script scripts/Deploy.s.sol:deployTestnet --rpc-url $GOERLI_RPC_URL --broadcast
```

## Running the Keeper

### Production
```bash
npm run keeper
```

### Development (with auto-reload)
```bash
npm run keeper:dev
```

## Testing

### Run all tests
```bash
forge test
```

### Run with mainnet fork
```bash
forge test --fork-url $MAINNET_RPC_URL
```

### Gas reports
```bash
forge test --gas-report
```

## Arbitrage Strategies

### stETH/ETH Arbitrage

Exploits price differences between stETH and ETH across different venues:
1. Flash borrow ETH from Balancer (0% fee)
2. Buy stETH at discount on Curve
3. Sell stETH for ETH on another DEX
4. Repay flash loan and keep profit

**Typical Returns**: 10-40 bps on market dislocations

### DAI Peg Arbitrage

Captures profit when DAI trades away from $1:
1. Flash mint DAI from Maker (0% fee)
2. When DAI > $1: Sell DAI for USDC, buy back cheaper
3. When DAI < $1: Buy cheap DAI, sell at peg
4. Repay flash mint and keep profit

**Typical Returns**: 5-20 bps during peg deviations

## Risk Management

- **Minimum Profit Threshold**: Configurable minimum profit requirement
- **Gas Price Limits**: Skip execution during high gas periods
- **Slippage Protection**: Built-in slippage tolerance
- **Access Control**: Keeper-only execution, owner-only admin functions

## Monitoring

The keeper provides comprehensive logging:
- Opportunity detection
- Execution status
- Profit tracking
- Error reporting

Logs are stored in:
- `logs/combined.log` - All activity
- `logs/error.log` - Errors only

## Security Considerations

1. **Private Key Management**: Never commit private keys
2. **Access Control**: Strict keeper/owner separation
3. **Reentrancy Protection**: All state changes protected
4. **Flash Loan Safety**: Validates callback sender

## Gas Optimization

- Minimal storage operations
- Efficient swap routing
- Batched approvals
- Optimized compiler settings

## License

MIT