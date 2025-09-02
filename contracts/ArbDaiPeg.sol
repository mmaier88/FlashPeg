// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IDssFlash.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ISwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract ArbDaiPeg is IERC3156FlashBorrower, Ownable, ReentrancyGuard {
    IDssFlash public immutable dssFlash;
    IERC20 public immutable dai;
    IERC20 public immutable usdc;
    
    address public keeper;
    uint256 public minProfitBps = 5; // 0.05% minimum profit
    
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    
    event ArbExecuted(uint256 flashAmount, uint256 profit);
    event KeeperUpdated(address indexed newKeeper);
    event MinProfitUpdated(uint256 newMinProfit);
    
    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Not keeper");
        _;
    }
    
    constructor(
        address _dssFlash,
        address _dai,
        address _usdc
    ) {
        dssFlash = IDssFlash(_dssFlash);
        dai = IERC20(_dai);
        usdc = IERC20(_usdc);
        keeper = msg.sender;
    }
    
    struct ArbParams {
        uint256 minDaiBack;
        address swapRouter;
        bytes swapData;
        bool isDaiOverPeg; // true if DAI > $1, false if DAI < $1
    }
    
    function executeArbitrage(
        uint256 flashAmount,
        uint256 minDaiBack,
        address swapRouter,
        bytes calldata swapData,
        bool isDaiOverPeg
    ) external onlyKeeper nonReentrant {
        ArbParams memory params = ArbParams({
            minDaiBack: minDaiBack,
            swapRouter: swapRouter,
            swapData: swapData,
            isDaiOverPeg: isDaiOverPeg
        });
        
        bytes memory data = abi.encode(params);
        
        // Flash mint DAI with 0% fee
        dssFlash.flashLoan(
            address(this),
            address(dai),
            flashAmount,
            data
        );
    }
    
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(dssFlash), "Not DssFlash");
        require(initiator == address(this), "Not self-initiated");
        require(token == address(dai), "Wrong token");
        require(fee == 0, "Fee should be 0"); // Maker flash mint has 0 fee
        
        ArbParams memory params = abi.decode(data, (ArbParams));
        
        if (params.isDaiOverPeg) {
            // DAI trading above peg: sell DAI for USDC, buy back cheaper
            _arbDaiOverPeg(amount, params);
        } else {
            // DAI trading below peg: buy cheap DAI with USDC
            _arbDaiUnderPeg(amount, params);
        }
        
        // Approve DssFlash to pull back the minted DAI
        dai.approve(address(dssFlash), amount);
        
        return CALLBACK_SUCCESS;
    }
    
    function _arbDaiOverPeg(uint256 daiAmount, ArbParams memory params) private {
        // When DAI > $1:
        // 1. Sell minted DAI for USDC at premium
        // 2. Buy back DAI at lower price
        // 3. Keep difference
        
        dai.approve(params.swapRouter, daiAmount);
        
        // Execute swap: DAI -> USDC
        (bool success,) = params.swapRouter.call(params.swapData);
        require(success, "DAI to USDC swap failed");
        
        uint256 usdcReceived = usdc.balanceOf(address(this));
        require(usdcReceived > 0, "No USDC received");
        
        // Buy back DAI with USDC at better rate
        usdc.approve(params.swapRouter, usdcReceived);
        
        // This would be another swap call with different data
        // For now, simplified - in production, would need second swap data
        
        uint256 daiBalance = dai.balanceOf(address(this));
        require(daiBalance >= daiAmount + params.minDaiBack, "Insufficient profit");
        
        // Send profit to keeper
        uint256 profit = daiBalance - daiAmount;
        if (profit > 0) {
            dai.transfer(keeper, profit);
            emit ArbExecuted(daiAmount, profit);
        }
    }
    
    function _arbDaiUnderPeg(uint256 daiAmount, ArbParams memory params) private {
        // When DAI < $1:
        // 1. Use minted DAI to acquire USDC
        // 2. Swap USDC back to DAI at better rate
        // 3. Repay flash loan and keep difference
        
        // This is more complex and requires initial USDC liquidity
        // Simplified implementation
        revert("DAI under peg arb not yet implemented");
    }
    
    function calculateProfit(
        uint256 flashAmount,
        uint256 daiPrice, // in basis points, 10000 = $1.00
        uint256 usdcPrice  // in basis points, 10000 = $1.00
    ) external view returns (uint256 expectedProfit, bool isProfitable) {
        if (daiPrice > usdcPrice) {
            // DAI over peg scenario
            uint256 usdcFromDai = (flashAmount * daiPrice) / 10000;
            uint256 daiFromUsdc = (usdcFromDai * 10000) / usdcPrice;
            
            if (daiFromUsdc > flashAmount) {
                expectedProfit = daiFromUsdc - flashAmount;
                isProfitable = (expectedProfit * 10000) / flashAmount >= minProfitBps;
            }
        }
    }
    
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "Invalid keeper");
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }
    
    function setMinProfit(uint256 _minProfitBps) external onlyOwner {
        minProfitBps = _minProfitBps;
        emit MinProfitUpdated(_minProfitBps);
    }
    
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
}