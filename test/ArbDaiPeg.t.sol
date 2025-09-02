// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/ArbDaiPeg.sol";

contract ArbDaiPegTest is Test {
    ArbDaiPeg public arbContract;
    
    address constant MAKER_DSS_FLASH = 0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    address keeper = makeAddr("keeper");
    address owner = makeAddr("owner");
    
    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        
        // Deploy contract
        vm.prank(owner);
        arbContract = new ArbDaiPeg(
            MAKER_DSS_FLASH,
            DAI,
            USDC
        );
        
        // Set keeper
        vm.prank(owner);
        arbContract.setKeeper(keeper);
        
        // Fund keeper with ETH for gas
        vm.deal(keeper, 10 ether);
    }
    
    function testDeployment() public {
        assertEq(address(arbContract.dssFlash()), MAKER_DSS_FLASH);
        assertEq(address(arbContract.dai()), DAI);
        assertEq(address(arbContract.usdc()), USDC);
        assertEq(arbContract.keeper(), keeper);
        assertEq(arbContract.owner(), owner);
    }
    
    function testOnlyKeeperCanExecute() public {
        address notKeeper = makeAddr("notKeeper");
        
        vm.prank(notKeeper);
        vm.expectRevert("Not keeper");
        arbContract.executeArbitrage(
            1000000 ether, // 1M DAI
            0,
            address(0),
            "",
            true
        );
    }
    
    function testCalculateProfit() public view {
        // Test with DAI over peg (DAI = $1.002, USDC = $1.000)
        uint256 daiPrice = 10020; // $1.002 in basis points
        uint256 usdcPrice = 10000; // $1.000 in basis points
        
        (uint256 profit, bool isProfitable) = arbContract.calculateProfit(
            1000000 ether, // 1M DAI
            daiPrice,
            usdcPrice
        );
        
        console.log("Expected profit:", profit);
        console.log("Is profitable:", isProfitable);
        
        // With 20 bps spread on 1M DAI, should be profitable
        assertTrue(profit > 0);
    }
    
    function testFlashLoanCallback() public {
        // Test that only DssFlash can call the callback
        vm.expectRevert("Not DssFlash");
        arbContract.onFlashLoan(
            address(this),
            DAI,
            1000000 ether,
            0,
            ""
        );
    }
    
    function testMinProfitSetting() public {
        uint256 newMinProfit = 10; // 0.1%
        
        // Only owner can set
        vm.prank(keeper);
        vm.expectRevert();
        arbContract.setMinProfit(newMinProfit);
        
        // Owner sets new minimum
        vm.prank(owner);
        arbContract.setMinProfit(newMinProfit);
        assertEq(arbContract.minProfitBps(), newMinProfit);
    }
    
    function testRescueTokens() public {
        // Send some DAI to contract
        deal(DAI, address(arbContract), 1000 ether);
        
        uint256 balanceBefore = IERC20(DAI).balanceOf(owner);
        
        // Only owner can rescue
        vm.prank(keeper);
        vm.expectRevert();
        arbContract.rescueTokens(DAI, 1000 ether);
        
        // Owner rescues tokens
        vm.prank(owner);
        arbContract.rescueTokens(DAI, 1000 ether);
        
        uint256 balanceAfter = IERC20(DAI).balanceOf(owner);
        assertEq(balanceAfter - balanceBefore, 1000 ether);
    }
    
    // Integration test - requires mainnet fork
    function testDaiOverPegScenario() public {
        // Simulate DAI trading over peg
        uint256 flashAmount = 1000000 ether; // 1M DAI
        
        // Check if profitable at current market conditions
        (uint256 expectedProfit, bool isProfitable) = arbContract.calculateProfit(
            flashAmount,
            10015, // DAI at $1.0015
            10000  // USDC at $1.00
        );
        
        if (isProfitable) {
            console.log("DAI over peg opportunity:", expectedProfit);
            // Would execute if we had proper swap data
        } else {
            console.log("No profitable DAI over peg opportunity");
        }
    }
}