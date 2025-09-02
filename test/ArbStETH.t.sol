// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/ArbStETH.sol";
import "../contracts/interfaces/IBalancerVault.sol";

contract ArbStETHTest is Test {
    ArbStETH public arbContract;
    
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant CURVE_STETH_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    
    address keeper = makeAddr("keeper");
    address owner = makeAddr("owner");
    
    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        
        // Deploy contract
        vm.prank(owner);
        arbContract = new ArbStETH(
            BALANCER_VAULT,
            CURVE_STETH_POOL,
            WETH,
            STETH
        );
        
        // Set keeper
        vm.prank(owner);
        arbContract.setKeeper(keeper);
        
        // Fund keeper with ETH for gas
        vm.deal(keeper, 10 ether);
    }
    
    function testDeployment() public {
        assertEq(address(arbContract.balancerVault()), BALANCER_VAULT);
        assertEq(address(arbContract.curveStEthPool()), CURVE_STETH_POOL);
        assertEq(address(arbContract.weth()), WETH);
        assertEq(address(arbContract.stETH()), STETH);
        assertEq(arbContract.keeper(), keeper);
        assertEq(arbContract.owner(), owner);
    }
    
    function testOnlyKeeperCanExecute() public {
        address notKeeper = makeAddr("notKeeper");
        
        address[] memory swapPath = new address[](1);
        swapPath[0] = address(0);
        
        vm.prank(notKeeper);
        vm.expectRevert("Not keeper");
        arbContract.executeArbitrage(
            1 ether,
            0,
            swapPath,
            ""
        );
    }
    
    function testSetKeeper() public {
        address newKeeper = makeAddr("newKeeper");
        
        // Only owner can set keeper
        vm.prank(keeper);
        vm.expectRevert();
        arbContract.setKeeper(newKeeper);
        
        // Owner can set keeper
        vm.prank(owner);
        arbContract.setKeeper(newKeeper);
        assertEq(arbContract.keeper(), newKeeper);
    }
    
    function testCalculateProfit() public view {
        (uint256 profit, bool isProfitable) = arbContract.calculateProfit(100 ether);
        
        // The actual profitability depends on current market conditions
        console.log("Expected profit:", profit);
        console.log("Is profitable:", isProfitable);
    }
    
    function testFlashLoanCallback() public {
        // Test that only Balancer Vault can call the callback
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory fees = new uint256[](1);
        
        tokens[0] = WETH;
        amounts[0] = 100 ether;
        fees[0] = 0;
        
        vm.expectRevert("Not Balancer Vault");
        arbContract.receiveFlashLoan(tokens, amounts, fees, "");
    }
    
    function testRescueTokens() public {
        // Send some WETH to contract
        deal(WETH, address(arbContract), 1 ether);
        
        uint256 balanceBefore = IERC20(WETH).balanceOf(owner);
        
        // Only owner can rescue
        vm.prank(keeper);
        vm.expectRevert();
        arbContract.rescueTokens(WETH, 1 ether);
        
        // Owner rescues tokens
        vm.prank(owner);
        arbContract.rescueTokens(WETH, 1 ether);
        
        uint256 balanceAfter = IERC20(WETH).balanceOf(owner);
        assertEq(balanceAfter - balanceBefore, 1 ether);
    }
    
    // Integration test - requires mainnet fork
    function testArbitrageExecution() public {
        // This test would execute an actual arbitrage on mainnet fork
        // Skip if no profitable opportunity exists
        
        (uint256 expectedProfit, bool isProfitable) = arbContract.calculateProfit(10 ether);
        
        if (!isProfitable) {
            console.log("No profitable opportunity at current market conditions");
            return;
        }
        
        // Would need to mock swap path and data for actual execution
        console.log("Profitable opportunity found:", expectedProfit);
    }
}