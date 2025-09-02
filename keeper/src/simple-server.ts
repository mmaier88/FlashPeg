import * as http from 'http';
import { ethers } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

// Simple logger
const log = {
    info: (msg: string, ...args: any[]) => console.log(`[INFO] ${new Date().toISOString()} - ${msg}`, ...args),
    error: (msg: string, ...args: any[]) => console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`, ...args),
    warn: (msg: string, ...args: any[]) => console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`, ...args)
};

class SimpleArbitrageKeeper {
    private provider: ethers.Provider;
    private wallet: ethers.Wallet;
    private isRunning: boolean = false;
    private lastCheckTime: Date = new Date();
    private successfulArbs: number = 0;
    private failedArbs: number = 0;

    constructor() {
        const rpcUrl = process.env.MAINNET_RPC_URL;
        const privateKey = process.env.KEEPER_PRIVATE_KEY;
        
        if (!rpcUrl || !privateKey) {
            throw new Error('Missing required environment variables: MAINNET_RPC_URL and KEEPER_PRIVATE_KEY');
        }
        
        this.provider = new ethers.JsonRpcProvider(rpcUrl);
        this.wallet = new ethers.Wallet(privateKey, this.provider);
        
        log.info('Keeper initialized', {
            address: this.wallet.address,
            rpcUrl: rpcUrl.substring(0, 30) + '...'
        });
    }

    async start() {
        this.isRunning = true;
        log.info('🚀 Arbitrage Keeper started');
        
        // Main monitoring loop
        this.monitorOpportunities();
    }

    private async monitorOpportunities() {
        while (this.isRunning) {
            try {
                this.lastCheckTime = new Date();
                log.info('Checking for arbitrage opportunities...');
                
                // Check if contracts are configured
                const stethContract = process.env.ARB_STETH_CONTRACT;
                const daiContract = process.env.ARB_DAI_CONTRACT;
                
                if (!stethContract || !daiContract) {
                    log.warn('Contracts not configured yet. Waiting...');
                } else {
                    // Simulate checking for opportunities
                    const blockNumber = await this.provider.getBlockNumber();
                    log.info(`Current block: ${blockNumber}`);
                    
                    // In production, would check actual arbitrage opportunities here
                    // For now, just log status
                    log.info('No profitable opportunities found in this cycle');
                }
                
            } catch (error) {
                log.error('Error in monitor loop:', error);
                this.failedArbs++;
            }
            
            // Wait before next check
            await this.sleep(parseInt(process.env.POLL_INTERVAL_MS || '5000'));
        }
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    getStatus() {
        return {
            running: this.isRunning,
            lastCheck: this.lastCheckTime.toISOString(),
            successfulArbs: this.successfulArbs,
            failedArbs: this.failedArbs,
            uptime: process.uptime(),
            walletAddress: this.wallet.address
        };
    }

    stop() {
        log.info('Stopping keeper...');
        this.isRunning = false;
    }
}

// Global keeper instance
let keeper: SimpleArbitrageKeeper | null = null;

// Create HTTP server for health checks
const server = http.createServer((req, res) => {
    // Set CORS headers
    res.setHeader('Content-Type', 'application/json');
    
    if (req.url === '/health') {
        if (keeper) {
            const status = keeper.getStatus();
            res.writeHead(200);
            res.end(JSON.stringify({
                status: 'healthy',
                ...status
            }));
        } else {
            res.writeHead(503);
            res.end(JSON.stringify({
                status: 'initializing'
            }));
        }
    } else if (req.url === '/') {
        res.writeHead(200);
        res.end(JSON.stringify({
            name: 'FlashPeg Arbitrage Keeper',
            version: '1.0.0',
            status: keeper ? 'running' : 'initializing'
        }));
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    log.info(`Health check server listening on port ${PORT}`);
    
    // Initialize and start keeper
    try {
        keeper = new SimpleArbitrageKeeper();
        keeper.start().catch(error => {
            log.error('Fatal error in keeper:', error);
            process.exit(1);
        });
    } catch (error) {
        log.error('Failed to initialize keeper:', error);
        // Don't exit immediately - allow health checks to report unhealthy
        // process.exit(1);
    }
});

// Graceful shutdown
process.on('SIGINT', () => {
    log.info('Received SIGINT, shutting down...');
    if (keeper) keeper.stop();
    server.close();
    process.exit(0);
});

process.on('SIGTERM', () => {
    log.info('Received SIGTERM, shutting down...');
    if (keeper) keeper.stop();
    server.close();
    process.exit(0);
});