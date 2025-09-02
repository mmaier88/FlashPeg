import { ethers } from 'ethers';
import dotenv from 'dotenv';
import { StETHArbitrage } from './strategies/stETHArbitrage';
import { DaiPegArbitrage } from './strategies/daiPegArbitrage';
import { logger } from './utils/logger';
import { config } from './config/config';

dotenv.config();

class ArbitrageKeeper {
    private provider: ethers.Provider;
    private wallet: ethers.Wallet;
    private stETHStrategy: StETHArbitrage;
    private daiStrategy: DaiPegArbitrage;
    private isRunning: boolean = false;

    constructor() {
        this.provider = new ethers.JsonRpcProvider(process.env.MAINNET_RPC_URL);
        this.wallet = new ethers.Wallet(process.env.KEEPER_PRIVATE_KEY!, this.provider);
        
        this.stETHStrategy = new StETHArbitrage(
            this.provider,
            this.wallet,
            process.env.ARB_STETH_CONTRACT!
        );
        
        this.daiStrategy = new DaiPegArbitrage(
            this.provider,
            this.wallet,
            process.env.ARB_DAI_CONTRACT!
        );
    }

    async start() {
        this.isRunning = true;
        logger.info('🚀 Arbitrage Keeper started');
        
        // Start monitoring loops
        this.monitorStETH();
        this.monitorDaiPeg();
        
        // Keep process alive
        process.on('SIGINT', () => this.stop());
        process.on('SIGTERM', () => this.stop());
    }

    private async monitorStETH() {
        while (this.isRunning) {
            try {
                const opportunity = await this.stETHStrategy.checkOpportunity();
                
                if (opportunity.isProfitable) {
                    logger.info(`💰 stETH opportunity found! Expected profit: ${opportunity.expectedProfit} ETH`);
                    
                    // Check gas price
                    const gasPrice = await this.provider.getFeeData();
                    if (gasPrice.gasPrice && gasPrice.gasPrice > ethers.parseUnits(config.maxGasPrice, 'gwei')) {
                        logger.warn('⛽ Gas price too high, skipping');
                        continue;
                    }
                    
                    // Execute arbitrage
                    const tx = await this.stETHStrategy.execute(opportunity);
                    logger.info(`✅ stETH arbitrage executed: ${tx.hash}`);
                    
                    // Wait for confirmation
                    await tx.wait();
                    logger.info('✅ Transaction confirmed');
                }
            } catch (error) {
                logger.error('❌ Error in stETH monitor:', error);
            }
            
            await this.sleep(config.pollInterval);
        }
    }

    private async monitorDaiPeg() {
        while (this.isRunning) {
            try {
                const opportunity = await this.daiStrategy.checkOpportunity();
                
                if (opportunity.isProfitable) {
                    logger.info(`💰 DAI peg opportunity found! Expected profit: ${opportunity.expectedProfit} DAI`);
                    
                    // Check gas price
                    const gasPrice = await this.provider.getFeeData();
                    if (gasPrice.gasPrice && gasPrice.gasPrice > ethers.parseUnits(config.maxGasPrice, 'gwei')) {
                        logger.warn('⛽ Gas price too high, skipping');
                        continue;
                    }
                    
                    // Execute arbitrage
                    const tx = await this.daiStrategy.execute(opportunity);
                    logger.info(`✅ DAI arbitrage executed: ${tx.hash}`);
                    
                    // Wait for confirmation
                    await tx.wait();
                    logger.info('✅ Transaction confirmed');
                }
            } catch (error) {
                logger.error('❌ Error in DAI monitor:', error);
            }
            
            await this.sleep(config.pollInterval);
        }
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    stop() {
        logger.info('⏹️ Stopping Arbitrage Keeper...');
        this.isRunning = false;
        process.exit(0);
    }
}

// Start keeper
const keeper = new ArbitrageKeeper();
keeper.start().catch(error => {
    logger.error('Fatal error:', error);
    process.exit(1);
});