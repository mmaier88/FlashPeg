// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IBalancerVault.sol";
import "./interfaces/ICurvePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ArbStETH is IFlashLoanRecipient, Ownable, ReentrancyGuard {
    IBalancerVault public immutable balancerVault;
    ICurvePool public immutable curveStEthPool;
    IERC20 public immutable weth;
    IERC20 public immutable stETH;
    
    address public keeper;
    uint256 public minProfitBps = 5; // 0.05% minimum profit
    
    event ArbExecuted(uint256 flashAmount, uint256 profit);
    event KeeperUpdated(address indexed newKeeper);
    event MinProfitUpdated(uint256 newMinProfit);
    
    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == owner(), "Not keeper");
        _;
    }
    
    constructor(
        address _vault,
        address _curvePool,
        address _weth,
        address _steth
    ) {
        balancerVault = IBalancerVault(_vault);
        curveStEthPool = ICurvePool(_curvePool);
        weth = IERC20(_weth);
        stETH = IERC20(_steth);
        keeper = msg.sender;
    }
    
    function executeArbitrage(
        uint256 flashAmount,
        uint256 minETHOut,
        address[] calldata swapPath,
        bytes calldata swapData
    ) external onlyKeeper nonReentrant {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(weth);
        amounts[0] = flashAmount;
        
        bytes memory userData = abi.encode(minETHOut, swapPath, swapData);
        balancerVault.flashLoan(address(this), tokens, amounts, userData);
    }
    
    function receiveFlashLoan(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata userData
    ) external override {
        require(msg.sender == address(balancerVault), "Not Balancer Vault");
        
        (uint256 minETHOut, address[] memory swapPath, bytes memory swapData) = 
            abi.decode(userData, (uint256, address[], bytes));
        
        uint256 flashAmount = amounts[0];
        uint256 flashFee = feeAmounts[0];
        uint256 totalDebt = flashAmount + flashFee;
        
        // Convert WETH to ETH for Curve
        weth.approve(address(curveStEthPool), flashAmount);
        
        // Step 1: Buy stETH on Curve at discount
        uint256 stETHReceived = curveStEthPool.exchange(
            0, // ETH index
            1, // stETH index
            flashAmount,
            0  // Will check profit at the end
        );
        
        // Step 2: Sell stETH back for ETH (via aggregator or direct swap)
        stETH.approve(swapPath[0], stETHReceived);
        
        // Execute swap via aggregator (1inch, 0x, etc) or direct DEX
        (bool success,) = swapPath[0].call(swapData);
        require(success, "Swap failed");
        
        // Check profit
        uint256 wethBalance = weth.balanceOf(address(this));
        require(wethBalance >= totalDebt + minETHOut, "Insufficient profit");
        
        // Repay flash loan
        weth.transfer(address(balancerVault), totalDebt);
        
        // Send profit to keeper
        uint256 profit = wethBalance - totalDebt;
        if (profit > 0) {
            weth.transfer(keeper, profit);
            emit ArbExecuted(flashAmount, profit);
        }
    }
    
    function calculateProfit(
        uint256 flashAmount
    ) external view returns (uint256 expectedProfit, bool isProfitable) {
        // Get expected stETH from Curve
        uint256 stETHOut = curveStEthPool.get_dy(0, 1, flashAmount);
        
        // Simplified profit calc (needs actual aggregator quote)
        uint256 ethBack = (stETHOut * 9995) / 10000; // Assume 0.05% slippage
        
        if (ethBack > flashAmount) {
            expectedProfit = ethBack - flashAmount;
            isProfitable = (expectedProfit * 10000) / flashAmount >= minProfitBps;
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
    
    receive() external payable {}
}