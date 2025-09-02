#!/bin/bash

# Load environment variables
source .env
source deployments/mainnet.env

echo "Verifying contracts on Etherscan..."

# Verify ArbStETH
forge verify-contract \
    --chain-id 1 \
    --compiler-version v0.8.24 \
    --optimizer-runs 200 \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address)" \
        "0xBA12222222228d8Ba445958a75a0704d566BF2C8" \
        "0xDC24316b9AE028F1497c275EB9192a3Ea0f67022" \
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2" \
        "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84") \
    $ARB_STETH_CONTRACT \
    contracts/ArbStETH.sol:ArbStETH

# Verify ArbDaiPeg
forge verify-contract \
    --chain-id 1 \
    --compiler-version v0.8.24 \
    --optimizer-runs 200 \
    --constructor-args $(cast abi-encode "constructor(address,address,address)" \
        "0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA" \
        "0x6B175474E89094C44Da98b954EedeAC495271d0F" \
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48") \
    $ARB_DAI_CONTRACT \
    contracts/ArbDaiPeg.sol:ArbDaiPeg

echo "Verification complete!"