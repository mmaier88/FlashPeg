import dotenv from 'dotenv';
dotenv.config();

export const config = {
    // Network settings
    rpcUrl: process.env.MAINNET_RPC_URL || '',
    chainId: 1, // Ethereum mainnet
    
    // Contract addresses
    arbStETHContract: process.env.ARB_STETH_CONTRACT || '',
    arbDaiContract: process.env.ARB_DAI_CONTRACT || '',
    
    // Keeper settings
    minProfitUsd: parseInt(process.env.MIN_PROFIT_USD || '100'),
    maxGasPrice: process.env.MAX_GAS_PRICE_GWEI || '50',
    pollInterval: parseInt(process.env.POLL_INTERVAL_MS || '5000'),
    
    // DEX contracts
    balancerVault: '0xBA12222222228d8Ba445958a75a0704d566BF2C8',
    curveStEthPool: '0xDC24316b9AE028F1497c275EB9192a3Ea0f67022',
    makerDssFlash: '0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA',
    
    // Token addresses
    weth: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    stETH: '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84',
    dai: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    usdc: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    
    // Notification settings
    discordWebhook: process.env.DISCORD_WEBHOOK_URL || '',
    telegramBotToken: process.env.TELEGRAM_BOT_TOKEN || '',
    telegramChatId: process.env.TELEGRAM_CHAT_ID || '',
    
    // Safety settings
    maxFlashLoanETH: '1000', // Maximum 1000 ETH per flash loan
    maxFlashLoanDAI: '10000000', // Maximum 10M DAI per flash loan
    minSpreadBps: 10, // Minimum 10 basis points spread to execute
    slippageTolerance: 50, // 0.5% slippage tolerance
};