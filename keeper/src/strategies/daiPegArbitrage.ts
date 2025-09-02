import { ethers } from 'ethers';
import { PriceMonitor } from '../utils/priceMonitor';
import { logger } from '../utils/logger';

const ArbDaiPeg_ABI = [
    "function executeArbitrage(uint256 flashAmount, uint256 minDaiBack, address swapRouter, bytes calldata swapData, bool isDaiOverPeg) external",
    "function calculateProfit(uint256 flashAmount, uint256 daiPrice, uint256 usdcPrice) external view returns (uint256 expectedProfit, bool isProfitable)"
];

export interface DaiOpportunity {
    isProfitable: boolean;
    expectedProfit: string;
    flashAmount: string;
    minDaiBack: string;
    swapRouter: string;
    swapData: string;
    isDaiOverPeg: boolean;
}

export class DaiPegArbitrage {
    private contract: ethers.Contract;
    private priceMonitor: PriceMonitor;
    
    constructor(
        private provider: ethers.Provider,
        private wallet: ethers.Wallet,
        contractAddress: string
    ) {
        this.contract = new ethers.Contract(contractAddress, ArbDaiPeg_ABI, wallet);
        this.priceMonitor = new PriceMonitor(provider);
    }
    
    async checkOpportunity(): Promise<DaiOpportunity> {
        try {
            // Get DAI and USDC prices from multiple sources
            const daiPrice = await this.priceMonitor.getDaiPrice();
            const usdcPrice = await this.priceMonitor.getUsdcPrice();
            
            // Calculate deviation from peg (both should be ~10000 for $1.00)
            const priceDiff = Math.abs(Number(daiPrice - usdcPrice));
            const isDaiOverPeg = daiPrice > usdcPrice;
            
            if (priceDiff < 10) { // Less than 10 bps difference
                return {
                    isProfitable: false,
                    expectedProfit: "0",
                    flashAmount: "0",
                    minDaiBack: "0",
                    swapRouter: "",
                    swapData: "0x",
                    isDaiOverPeg: false
                };
            }
            
            // Calculate optimal flash amount based on available liquidity
            const flashAmount = await this.calculateOptimalFlashAmount(priceDiff);
            
            // Check profitability via contract
            const [expectedProfit, isProfitable] = await this.contract.calculateProfit(
                flashAmount,
                daiPrice,
                usdcPrice
            );
            
            if (!isProfitable) {
                return {
                    isProfitable: false,
                    expectedProfit: "0",
                    flashAmount: "0",
                    minDaiBack: "0",
                    swapRouter: "",
                    swapData: "0x",
                    isDaiOverPeg: false
                };
            }
            
            // Build swap data
            const { swapRouter, swapData } = await this.buildSwapData(
                flashAmount,
                isDaiOverPeg
            );
            
            // Calculate minimum DAI back with slippage
            const minDaiBack = expectedProfit * 95n / 100n; // 5% slippage tolerance
            
            return {
                isProfitable: true,
                expectedProfit: ethers.formatUnits(expectedProfit, 18),
                flashAmount: flashAmount.toString(),
                minDaiBack: minDaiBack.toString(),
                swapRouter,
                swapData,
                isDaiOverPeg
            };
        } catch (error) {
            logger.error('Error checking DAI opportunity:', error);
            return {
                isProfitable: false,
                expectedProfit: "0",
                flashAmount: "0",
                minDaiBack: "0",
                swapRouter: "",
                swapData: "0x",
                isDaiOverPeg: false
            };
        }
    }
    
    async execute(opportunity: DaiOpportunity): Promise<ethers.TransactionResponse> {
        // Estimate gas
        const gasEstimate = await this.contract.executeArbitrage.estimateGas(
            opportunity.flashAmount,
            opportunity.minDaiBack,
            opportunity.swapRouter,
            opportunity.swapData,
            opportunity.isDaiOverPeg
        );
        
        // Add 20% buffer
        const gasLimit = gasEstimate * 120n / 100n;
        
        // Execute transaction
        const tx = await this.contract.executeArbitrage(
            opportunity.flashAmount,
            opportunity.minDaiBack,
            opportunity.swapRouter,
            opportunity.swapData,
            opportunity.isDaiOverPeg,
            { gasLimit }
        );
        
        return tx;
    }
    
    private async calculateOptimalFlashAmount(priceDiff: number): Promise<bigint> {
        // Base amount scaled by price difference
        const baseAmount = ethers.parseUnits("100000", 18); // 100k DAI base
        const multiplier = BigInt(Math.min(priceDiff / 5, 50)); // Scale up to 50x for large deviations
        
        // Check max flash mint capacity from Maker
        const maxFlash = ethers.parseUnits("500000000", 18); // 500M DAI max
        const calculated = baseAmount * multiplier;
        
        return calculated > maxFlash ? maxFlash : calculated;
    }
    
    private async buildSwapData(
        amount: bigint,
        isDaiOverPeg: boolean
    ): Promise<{ swapRouter: string, swapData: string }> {
        // Would integrate with DEX aggregator APIs (1inch, 0x, etc)
        // For now, using Curve as primary venue
        
        const swapRouter = "0x99a58482BD75cbab83b27EC03CA68fF489b5788f"; // Curve Router
        
        // In production, this would be actual encoded swap data
        const swapData = "0x"; // Placeholder
        
        return { swapRouter, swapData };
    }
}