import { ethers } from 'ethers';
import { PriceMonitor } from '../utils/priceMonitor';
import { logger } from '../utils/logger';

const ArbStETH_ABI = [
    "function executeArbitrage(uint256 flashAmount, uint256 minETHOut, address[] calldata swapPath, bytes calldata swapData) external",
    "function calculateProfit(uint256 flashAmount) external view returns (uint256 expectedProfit, bool isProfitable)"
];

export interface StETHOpportunity {
    isProfitable: boolean;
    expectedProfit: string;
    flashAmount: string;
    minETHOut: string;
    swapPath: string[];
    swapData: string;
}

export class StETHArbitrage {
    private contract: ethers.Contract;
    private priceMonitor: PriceMonitor;
    
    constructor(
        private provider: ethers.Provider,
        private wallet: ethers.Wallet,
        contractAddress: string
    ) {
        this.contract = new ethers.Contract(contractAddress, ArbStETH_ABI, wallet);
        this.priceMonitor = new PriceMonitor(provider);
    }
    
    async checkOpportunity(): Promise<StETHOpportunity> {
        try {
            // Get current prices from multiple sources
            const curvePrice = await this.priceMonitor.getCurveStETHPrice();
            const balancerPrice = await this.priceMonitor.getBalancerStETHPrice();
            const uniswapPrice = await this.priceMonitor.getUniswapStETHPrice();
            
            // Calculate spread
            const spread = this.calculateSpread(curvePrice, balancerPrice, uniswapPrice);
            
            if (spread.bps < 10) { // Less than 10 bps spread
                return {
                    isProfitable: false,
                    expectedProfit: "0",
                    flashAmount: "0",
                    minETHOut: "0",
                    swapPath: [],
                    swapData: "0x"
                };
            }
            
            // Determine optimal flash amount
            const flashAmount = await this.calculateOptimalFlashAmount(spread);
            
            // Simulate transaction
            const [expectedProfit, isProfitable] = await this.contract.calculateProfit(flashAmount);
            
            if (!isProfitable) {
                return {
                    isProfitable: false,
                    expectedProfit: "0",
                    flashAmount: "0",
                    minETHOut: "0",
                    swapPath: [],
                    swapData: "0x"
                };
            }
            
            // Build swap data for the arbitrage
            const { swapPath, swapData } = await this.buildSwapData(
                flashAmount,
                spread.bestBuyVenue,
                spread.bestSellVenue
            );
            
            // Calculate minimum output with slippage
            const minETHOut = expectedProfit * 95n / 100n; // 5% slippage tolerance
            
            return {
                isProfitable: true,
                expectedProfit: ethers.formatEther(expectedProfit),
                flashAmount: flashAmount.toString(),
                minETHOut: minETHOut.toString(),
                swapPath,
                swapData
            };
        } catch (error) {
            logger.error('Error checking stETH opportunity:', error);
            return {
                isProfitable: false,
                expectedProfit: "0",
                flashAmount: "0",
                minETHOut: "0",
                swapPath: [],
                swapData: "0x"
            };
        }
    }
    
    async execute(opportunity: StETHOpportunity): Promise<ethers.TransactionResponse> {
        // Estimate gas
        const gasEstimate = await this.contract.executeArbitrage.estimateGas(
            opportunity.flashAmount,
            opportunity.minETHOut,
            opportunity.swapPath,
            opportunity.swapData
        );
        
        // Add 20% buffer to gas estimate
        const gasLimit = gasEstimate * 120n / 100n;
        
        // Execute transaction
        const tx = await this.contract.executeArbitrage(
            opportunity.flashAmount,
            opportunity.minETHOut,
            opportunity.swapPath,
            opportunity.swapData,
            { gasLimit }
        );
        
        return tx;
    }
    
    private calculateSpread(curvePrice: bigint, balancerPrice: bigint, uniswapPrice: bigint) {
        const prices = [
            { venue: 'curve', price: curvePrice },
            { venue: 'balancer', price: balancerPrice },
            { venue: 'uniswap', price: uniswapPrice }
        ];
        
        prices.sort((a, b) => Number(a.price - b.price));
        
        const minPrice = prices[0].price;
        const maxPrice = prices[2].price;
        const spread = ((maxPrice - minPrice) * 10000n) / minPrice;
        
        return {
            bps: Number(spread),
            bestBuyVenue: prices[0].venue,
            bestSellVenue: prices[2].venue
        };
    }
    
    private async calculateOptimalFlashAmount(spread: any): Promise<bigint> {
        // Start with a base amount and scale based on spread
        const baseAmount = ethers.parseEther("100"); // 100 ETH base
        const multiplier = BigInt(Math.min(spread.bps / 10, 10)); // Scale up to 10x for high spreads
        
        return baseAmount * multiplier;
    }
    
    private async buildSwapData(
        amount: bigint,
        buyVenue: string,
        sellVenue: string
    ): Promise<{ swapPath: string[], swapData: string }> {
        // This would integrate with 1inch or 0x API for actual swap data
        // Simplified for demonstration
        
        const swapPath = [
            this.getRouterAddress(sellVenue)
        ];
        
        // In production, this would be actual calldata from aggregator API
        const swapData = "0x"; // Placeholder
        
        return { swapPath, swapData };
    }
    
    private getRouterAddress(venue: string): string {
        const routers: { [key: string]: string } = {
            'curve': '0x99a58482BD75cbab83b27EC03CA68fF489b5788f', // Curve Router
            'balancer': '0xBA12222222228d8Ba445958a75a0704d566BF2C8', // Balancer Vault
            'uniswap': '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45' // Uniswap Router V3
        };
        
        return routers[venue] || routers['uniswap'];
    }
}