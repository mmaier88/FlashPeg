import express from 'express';
import { ethers } from 'ethers';
import dotenv from 'dotenv';
import { StETHArbitrage } from './strategies/stETHArbitrage';
import { DaiPegArbitrage } from './strategies/daiPegArbitrage';
import { logger } from './utils/logger';
import { config } from './config/config';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

class ArbitrageKeeper {
    private provider: ethers.Provider;
    private wallet: ethers.Wallet;
    private stETHStrategy: StETHArbitrage;
    private daiStrategy: DaiPegArbitrage;
    private isRunning: boolean = false;
    private lastCheckTime: Date = new Date();
    private successfulArbs: number = 0;
    private failedArbs: number = 0;

    constructor() {
        if (!process.env.MAINNET_RPC_URL || !process.env.KEEPER_PRIVATE_KEY) {
            throw new Error('Missing required environment variables');
        }
        
        this.provider = new ethers.JsonRpcProvider(process.env.MAINNET_RPC_URL);
        this.wallet = new ethers.Wallet(process.env.KEEPER_PRIVATE_KEY, this.provider);
        
        if (process.env.ARB_STETH_CONTRACT) {
            this.stETHStrategy = new StETHArbitrage(
                this.provider,
                this.wallet,
                process.env.ARB_STETH_CONTRACT
            );
        }
        
        if (process.env.ARB_DAI_CONTRACT) {
            this.daiStrategy = new DaiPegArbitrage(
                this.provider,
                this.wallet,
                process.env.ARB_DAI_CONTRACT
            );
        }
    }

    async start() {
        this.isRunning = true;
        logger.info('🚀 Arbitrage Keeper started in production mode');
        
        // Start monitoring loops
        if (this.stETHStrategy) {
            this.monitorStETH();
        }
        if (this.daiStrategy) {
            this.monitorDaiPeg();
        }
    }

    private async monitorStETH() {
        while (this.isRunning) {
            try {
                this.lastCheckTime = new Date();
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
                    try {
                        const tx = await this.stETHStrategy.execute(opportunity);
                        logger.info(`✅ stETH arbitrage executed: ${tx.hash}`);
                        await tx.wait();
                        logger.info('✅ Transaction confirmed');
                        this.successfulArbs++;
                    } catch (error) {
                        logger.error('❌ Failed to execute stETH arbitrage:', error);
                        this.failedArbs++;
                    }
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
                this.lastCheckTime = new Date();
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
                    try {
                        const tx = await this.daiStrategy.execute(opportunity);
                        logger.info(`✅ DAI arbitrage executed: ${tx.hash}`);
                        await tx.wait();
                        logger.info('✅ Transaction confirmed');
                        this.successfulArbs++;
                    } catch (error) {
                        logger.error('❌ Failed to execute DAI arbitrage:', error);
                        this.failedArbs++;
                    }
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

    getStatus() {
        return {
            running: this.isRunning,
            lastCheck: this.lastCheckTime,
            successfulArbs: this.successfulArbs,
            failedArbs: this.failedArbs,
            uptime: process.uptime()
        };
    }

    stop() {
        logger.info('⏹️ Stopping Arbitrage Keeper...');
        this.isRunning = false;
    }
}

// Initialize keeper
let keeper: ArbitrageKeeper;

// Health check endpoint
app.get('/health', (req, res) => {
    if (keeper) {
        const status = keeper.getStatus();
        res.json({
            status: 'healthy',
            ...status
        });
    } else {
        res.status(503).json({
            status: 'initializing'
        });
    }
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
    if (keeper) {
        const status = keeper.getStatus();
        res.json({
            metrics: {
                uptime_seconds: status.uptime,
                successful_arbitrages: status.successfulArbs,
                failed_arbitrages: status.failedArbs,
                last_check_timestamp: status.lastCheck.getTime()
            }
        });
    } else {
        res.status(503).json({ error: 'Service not ready' });
    }
});

// Start server
app.listen(PORT, () => {
    logger.info(`Health check server listening on port ${PORT}`);
    
    // Start keeper
    try {
        keeper = new ArbitrageKeeper();
        keeper.start().catch(error => {
            logger.error('Fatal error in keeper:', error);
            process.exit(1);
        });
    } catch (error) {
        logger.error('Failed to initialize keeper:', error);
        process.exit(1);
    }
});

// Graceful shutdown
process.on('SIGINT', () => {
    logger.info('Received SIGINT, shutting down gracefully...');
    if (keeper) keeper.stop();
    process.exit(0);
});

process.on('SIGTERM', () => {
    logger.info('Received SIGTERM, shutting down gracefully...');
    if (keeper) keeper.stop();
    process.exit(0);
});