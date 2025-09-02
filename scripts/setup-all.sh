#!/bin/bash

# FlashPeg Complete Setup Script
# This script will help you deploy everything from scratch

set -e

echo "========================================="
echo "   FlashPeg Arbitrage Bot Setup"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "ℹ $1"; }

# Check if required tools are installed
check_requirements() {
    echo "Checking requirements..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        echo "Please install Node.js from https://nodejs.org/"
        exit 1
    else
        print_success "Node.js installed ($(node --version))"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    else
        print_success "npm installed ($(npm --version))"
    fi
    
    # Check if Foundry is installed
    if ! command -v forge &> /dev/null; then
        print_warning "Foundry not installed. Installing now..."
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc
        foundryup
        print_success "Foundry installed"
    else
        print_success "Foundry installed ($(forge --version | head -1))"
    fi
    
    echo ""
}

# Generate wallets
generate_wallets() {
    echo "========================================="
    echo "   Step 1: Generate Wallets"
    echo "========================================="
    echo ""
    
    if [ -f .env.generated ]; then
        print_warning "Wallets already generated. Loading existing..."
        source .env.generated
    else
        print_info "Generating new wallets..."
        
        # Generate deployer wallet
        node scripts/generate-wallet.js deployer > deployer-wallet.tmp
        DEPLOYER_ADDRESS=$(grep "Address:" deployer-wallet.tmp | cut -d' ' -f2)
        DEPLOYER_KEY=$(grep "Private Key:" deployer-wallet.tmp | cut -d' ' -f3)
        
        # Generate keeper wallet  
        node scripts/generate-wallet.js keeper > keeper-wallet.tmp
        KEEPER_ADDRESS=$(grep "Address:" keeper-wallet.tmp | cut -d' ' -f2)
        KEEPER_KEY=$(grep "Private Key:" keeper-wallet.tmp | cut -d' ' -f3)
        
        # Save to .env.generated
        cat > .env.generated << EOF
# Generated Wallets - KEEP THESE SECRET!
DEPLOYER_ADDRESS=$DEPLOYER_ADDRESS
DEPLOYER_PRIVATE_KEY=$DEPLOYER_KEY
KEEPER_ADDRESS=$KEEPER_ADDRESS
KEEPER_PRIVATE_KEY=$KEEPER_KEY
EOF
        
        # Clean up temp files
        rm deployer-wallet.tmp keeper-wallet.tmp
        
        print_success "Wallets generated and saved to .env.generated"
        print_warning "IMPORTANT: Save these keys securely!"
        echo ""
        echo "Deployer Address: $DEPLOYER_ADDRESS"
        echo "Keeper Address: $KEEPER_ADDRESS"
        echo ""
    fi
}

# Get RPC URL
setup_rpc() {
    echo "========================================="
    echo "   Step 2: Setup RPC Provider"
    echo "========================================="
    echo ""
    
    if [ -z "$MAINNET_RPC_URL" ]; then
        print_info "You need an Ethereum RPC URL."
        echo ""
        echo "Options:"
        echo "1) Alchemy (recommended) - https://www.alchemy.com/"
        echo "2) Infura - https://infura.io/"
        echo "3) QuickNode - https://www.quicknode.com/"
        echo ""
        read -p "Enter your RPC URL (or 'skip' for testnet): " RPC_URL
        
        if [ "$RPC_URL" = "skip" ]; then
            print_info "Using Goerli testnet"
            export MAINNET_RPC_URL="https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"
            export NETWORK="goerli"
        else
            export MAINNET_RPC_URL=$RPC_URL
            export NETWORK="mainnet"
        fi
        
        # Save to .env
        echo "MAINNET_RPC_URL=$MAINNET_RPC_URL" >> .env.generated
        echo "NETWORK=$NETWORK" >> .env.generated
    fi
    
    print_success "RPC configured for $NETWORK"
    echo ""
}

# Check wallet balances
check_balances() {
    echo "========================================="
    echo "   Step 3: Check Wallet Balances"
    echo "========================================="
    echo ""
    
    source .env.generated
    
    print_info "Checking balances..."
    
    # Check deployer balance
    DEPLOYER_BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $MAINNET_RPC_URL | sed 's/[^0-9]//g')
    DEPLOYER_ETH=$(echo "scale=4; $DEPLOYER_BALANCE / 1000000000000000000" | bc 2>/dev/null || echo "0")
    
    # Check keeper balance
    KEEPER_BALANCE=$(cast balance $KEEPER_ADDRESS --rpc-url $MAINNET_RPC_URL | sed 's/[^0-9]//g')
    KEEPER_ETH=$(echo "scale=4; $KEEPER_BALANCE / 1000000000000000000" | bc 2>/dev/null || echo "0")
    
    echo "Deployer Balance: $DEPLOYER_ETH ETH"
    echo "Keeper Balance: $KEEPER_ETH ETH"
    echo ""
    
    if [ "$NETWORK" = "mainnet" ]; then
        REQUIRED_DEPLOYER="0.3"
        REQUIRED_KEEPER="0.5"
    else
        REQUIRED_DEPLOYER="0.1"
        REQUIRED_KEEPER="0.1"
    fi
    
    # Check if balances are sufficient
    if (( $(echo "$DEPLOYER_ETH < $REQUIRED_DEPLOYER" | bc -l) )); then
        print_warning "Deployer needs at least $REQUIRED_DEPLOYER ETH"
        echo "Send ETH to: $DEPLOYER_ADDRESS"
        
        if [ "$NETWORK" = "goerli" ]; then
            echo ""
            print_info "Get Goerli ETH from: https://goerlifaucet.com/"
        fi
        
        read -p "Press Enter when funded or 'skip' to continue anyway: " WAIT
    else
        print_success "Deployer has sufficient balance"
    fi
    
    if (( $(echo "$KEEPER_ETH < $REQUIRED_KEEPER" | bc -l) )); then
        print_warning "Keeper needs at least $REQUIRED_KEEPER ETH"
        echo "Send ETH to: $KEEPER_ADDRESS"
        
        if [ "$NETWORK" = "goerli" ]; then
            echo ""
            print_info "Get Goerli ETH from: https://goerlifaucet.com/"
        fi
        
        read -p "Press Enter when funded or 'skip' to continue anyway: " WAIT
    else
        print_success "Keeper has sufficient balance"
    fi
    
    echo ""
}

# Deploy contracts
deploy_contracts() {
    echo "========================================="
    echo "   Step 4: Deploy Smart Contracts"
    echo "========================================="
    echo ""
    
    source .env.generated
    
    print_info "Installing dependencies..."
    npm install > /dev/null 2>&1
    forge install > /dev/null 2>&1
    print_success "Dependencies installed"
    
    print_info "Building contracts..."
    forge build > /dev/null 2>&1
    print_success "Contracts built"
    
    print_info "Deploying contracts to $NETWORK..."
    
    # Deploy and capture output
    if [ "$NETWORK" = "goerli" ]; then
        DEPLOY_OUTPUT=$(forge script scripts/Deploy.s.sol:deployTestnet \
            --rpc-url $MAINNET_RPC_URL \
            --private-key $DEPLOYER_PRIVATE_KEY \
            --broadcast 2>&1)
    else
        DEPLOY_OUTPUT=$(forge script scripts/Deploy.s.sol \
            --rpc-url $MAINNET_RPC_URL \
            --private-key $DEPLOYER_PRIVATE_KEY \
            --broadcast 2>&1)
    fi
    
    # Extract contract addresses from output
    ARB_STETH=$(echo "$DEPLOY_OUTPUT" | grep "ArbStETH deployed at:" | awk '{print $NF}')
    ARB_DAI=$(echo "$DEPLOY_OUTPUT" | grep "ArbDaiPeg deployed at:" | awk '{print $NF}')
    
    if [ -z "$ARB_STETH" ] || [ -z "$ARB_DAI" ]; then
        print_error "Contract deployment failed"
        echo "$DEPLOY_OUTPUT"
        exit 1
    fi
    
    # Save contract addresses
    cat >> .env.generated << EOF

# Deployed Contracts
ARB_STETH_CONTRACT=$ARB_STETH
ARB_DAI_CONTRACT=$ARB_DAI
EOF
    
    print_success "Contracts deployed!"
    echo ""
    echo "ArbStETH: $ARB_STETH"
    echo "ArbDaiPeg: $ARB_DAI"
    echo ""
    
    # Verify on Etherscan
    if [ "$NETWORK" = "mainnet" ]; then
        read -p "Verify contracts on Etherscan? (y/n): " VERIFY
        if [ "$VERIFY" = "y" ]; then
            ./scripts/verify.sh
        fi
    fi
}

# Generate Render configuration
generate_render_config() {
    echo "========================================="
    echo "   Step 5: Generate Render Config"
    echo "========================================="
    echo ""
    
    source .env.generated
    
    print_info "Generating Render deployment configuration..."
    
    # Create .env.render.ready with actual values
    cat > .env.render.ready << EOF
# Ready for Render Deployment
# Copy these values to Render Environment Variables

MAINNET_RPC_URL=$MAINNET_RPC_URL
KEEPER_PRIVATE_KEY=$KEEPER_PRIVATE_KEY
ARB_STETH_CONTRACT=$ARB_STETH_CONTRACT
ARB_DAI_CONTRACT=$ARB_DAI_CONTRACT
MIN_PROFIT_USD=100
MAX_GAS_PRICE_GWEI=50
POLL_INTERVAL_MS=5000
LOG_LEVEL=info
EOF
    
    print_success "Render configuration saved to .env.render.ready"
    echo ""
}

# Display final instructions
show_deployment_instructions() {
    echo "========================================="
    echo "   ✅ Setup Complete!"
    echo "========================================="
    echo ""
    
    source .env.generated
    
    print_success "All components are ready for deployment!"
    echo ""
    echo "📋 Your Configuration:"
    echo "----------------------"
    echo "Network: $NETWORK"
    echo "Deployer: $DEPLOYER_ADDRESS"
    echo "Keeper: $KEEPER_ADDRESS"
    echo "ArbStETH: $ARB_STETH_CONTRACT"
    echo "ArbDaiPeg: $ARB_DAI_CONTRACT"
    echo ""
    
    echo "🚀 Deploy to Render:"
    echo "--------------------"
    echo "1. Go to https://dashboard.render.com/"
    echo "2. Click 'New +' → 'Background Worker'"
    echo "3. Connect GitHub: https://github.com/mmaier88/FlashPeg"
    echo "4. Add these environment variables:"
    echo ""
    echo "   MAINNET_RPC_URL = $MAINNET_RPC_URL"
    echo "   KEEPER_PRIVATE_KEY = $KEEPER_PRIVATE_KEY (🔒 Mark as Secret!)"
    echo "   ARB_STETH_CONTRACT = $ARB_STETH_CONTRACT"
    echo "   ARB_DAI_CONTRACT = $ARB_DAI_CONTRACT"
    echo ""
    echo "5. Click 'Create Background Worker'"
    echo ""
    
    print_warning "⚠️  IMPORTANT:"
    echo "   - Click the lock icon 🔒 for KEEPER_PRIVATE_KEY"
    echo "   - Save .env.generated file securely"
    echo "   - Never share your private keys"
    echo ""
    
    print_info "📄 All settings saved to: .env.render.ready"
}

# Main execution
main() {
    clear
    check_requirements
    generate_wallets
    setup_rpc
    check_balances
    deploy_contracts
    generate_render_config
    show_deployment_instructions
}

# Run main function
main