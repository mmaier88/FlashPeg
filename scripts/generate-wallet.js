#!/usr/bin/env node

const { ethers } = require('ethers');

// Generate a new wallet
function generateWallet(label = 'wallet') {
    const wallet = ethers.Wallet.createRandom();
    
    console.log(`\n${label.toUpperCase()} WALLET GENERATED`);
    console.log('='.repeat(50));
    console.log(`Address: ${wallet.address}`);
    console.log(`Private Key: ${wallet.privateKey}`);
    console.log('='.repeat(50));
    console.log('\n⚠️  IMPORTANT: Save these credentials securely!');
    console.log('Never share your private key with anyone.');
    
    return {
        address: wallet.address,
        privateKey: wallet.privateKey
    };
}

// Get label from command line arguments
const label = process.argv[2] || 'wallet';

// Generate and display wallet
generateWallet(label);