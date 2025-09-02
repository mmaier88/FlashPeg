import { ethers } from 'ethers';

const CURVE_STETH_POOL = "0xDC24316b9AE028F1497c275EB9192a3Ea0f67022";
const BALANCER_STETH_POOL = "0x32296969Ef14EB0c6d29669C550D4a0449130230";
const CHAINLINK_DAI_USD = "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9";
const CHAINLINK_USDC_USD = "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6";

const CURVE_POOL_ABI = [
    "function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256)",
    "function price_oracle() external view returns (uint256)"
];

const CHAINLINK_ABI = [
    "function latestRoundData() external view returns (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)"
];

export class PriceMonitor {
    constructor(private provider: ethers.Provider) {}
    
    async getCurveStETHPrice(): Promise<bigint> {
        try {
            const pool = new ethers.Contract(CURVE_STETH_POOL, CURVE_POOL_ABI, this.provider);
            const price = await pool.price_oracle();
            return price;
        } catch (error) {
            console.error('Error fetching Curve stETH price:', error);
            return 0n;
        }
    }
    
    async getBalancerStETHPrice(): Promise<bigint> {
        // Query Balancer pool for stETH price
        // This would use Balancer's vault query functions
        try {
            // Simplified - would need actual Balancer pool query
            return ethers.parseEther("0.995"); // Example: stETH at 0.995 ETH
        } catch (error) {
            console.error('Error fetching Balancer stETH price:', error);
            return 0n;
        }
    }
    
    async getUniswapStETHPrice(): Promise<bigint> {
        // Query Uniswap V3 pool for stETH price
        try {
            // Simplified - would need actual Uniswap V3 pool query
            return ethers.parseEther("0.997"); // Example: stETH at 0.997 ETH
        } catch (error) {
            console.error('Error fetching Uniswap stETH price:', error);
            return 0n;
        }
    }
    
    async getDaiPrice(): Promise<bigint> {
        try {
            const priceFeed = new ethers.Contract(CHAINLINK_DAI_USD, CHAINLINK_ABI, this.provider);
            const roundData = await priceFeed.latestRoundData();
            // Chainlink returns 8 decimals, convert to basis points (10000 = $1.00)
            return BigInt(roundData.price) * 100n / 1000000n;
        } catch (error) {
            console.error('Error fetching DAI price:', error);
            return 10000n; // Default to $1.00
        }
    }
    
    async getUsdcPrice(): Promise<bigint> {
        try {
            const priceFeed = new ethers.Contract(CHAINLINK_USDC_USD, CHAINLINK_ABI, this.provider);
            const roundData = await priceFeed.latestRoundData();
            // Chainlink returns 8 decimals, convert to basis points
            return BigInt(roundData.price) * 100n / 1000000n;
        } catch (error) {
            console.error('Error fetching USDC price:', error);
            return 10000n; // Default to $1.00
        }
    }
    
    async getGasPrice(): Promise<bigint> {
        const feeData = await this.provider.getFeeData();
        return feeData.gasPrice || ethers.parseUnits("30", "gwei");
    }
}