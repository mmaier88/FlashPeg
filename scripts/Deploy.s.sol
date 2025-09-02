// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/ArbStETH.sol";
import "../contracts/ArbDaiPeg.sol";

contract Deploy is Script {
    // Mainnet addresses
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant CURVE_STETH_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address constant MAKER_DSS_FLASH = 0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy stETH arbitrage contract
        ArbStETH arbStETH = new ArbStETH(
            BALANCER_VAULT,
            CURVE_STETH_POOL,
            WETH,
            STETH
        );
        console.log("ArbStETH deployed at:", address(arbStETH));
        
        // Deploy DAI peg arbitrage contract
        ArbDaiPeg arbDaiPeg = new ArbDaiPeg(
            MAKER_DSS_FLASH,
            DAI,
            USDC
        );
        console.log("ArbDaiPeg deployed at:", address(arbDaiPeg));
        
        // Set keeper address (can be updated later)
        address keeper = vm.envAddress("KEEPER_ADDRESS");
        if (keeper != address(0)) {
            arbStETH.setKeeper(keeper);
            arbDaiPeg.setKeeper(keeper);
            console.log("Keeper set to:", keeper);
        }
        
        vm.stopBroadcast();
        
        // Save deployment addresses
        string memory deploymentInfo = string(abi.encodePacked(
            "ARB_STETH_CONTRACT=", vm.toString(address(arbStETH)), "\n",
            "ARB_DAI_CONTRACT=", vm.toString(address(arbDaiPeg)), "\n"
        ));
        
        vm.writeFile("deployments/mainnet.env", deploymentInfo);
        console.log("Deployment addresses saved to deployments/mainnet.env");
    }
    
    function deployTestnet() public {
        // Goerli testnet deployment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying to Goerli testnet with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Goerli testnet addresses (these are example addresses, some may not exist)
        address GOERLI_BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8; // Same on Goerli
        address GOERLI_CURVE_POOL = 0x0000000000000000000000000000000000000000; // Placeholder
        address GOERLI_DSS_FLASH = 0x0000000000000000000000000000000000000000; // Placeholder
        address GOERLI_WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // Goerli WETH
        address GOERLI_STETH = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F; // Goerli stETH
        address GOERLI_DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844; // Goerli DAI
        address GOERLI_USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // Goerli USDC
        
        // Deploy stETH arbitrage contract
        ArbStETH arbStETH = new ArbStETH(
            GOERLI_BALANCER_VAULT,
            GOERLI_CURVE_POOL != address(0) ? GOERLI_CURVE_POOL : GOERLI_BALANCER_VAULT,
            GOERLI_WETH,
            GOERLI_STETH
        );
        console.log("ArbStETH deployed at:", address(arbStETH));
        
        // Deploy DAI peg arbitrage contract
        ArbDaiPeg arbDaiPeg = new ArbDaiPeg(
            GOERLI_DSS_FLASH != address(0) ? GOERLI_DSS_FLASH : address(arbStETH), // Use dummy address if not available
            GOERLI_DAI,
            GOERLI_USDC
        );
        console.log("ArbDaiPeg deployed at:", address(arbDaiPeg));
        
        // Set keeper address
        address keeper = vm.envAddress("KEEPER_ADDRESS");
        if (keeper == address(0)) {
            keeper = deployer; // Use deployer as keeper for testing
        }
        
        arbStETH.setKeeper(keeper);
        arbDaiPeg.setKeeper(keeper);
        console.log("Keeper set to:", keeper);
        
        vm.stopBroadcast();
        
        // Save deployment addresses
        string memory deploymentInfo = string(abi.encodePacked(
            "ARB_STETH_CONTRACT=", vm.toString(address(arbStETH)), "\n",
            "ARB_DAI_CONTRACT=", vm.toString(address(arbDaiPeg)), "\n"
        ));
        
        vm.writeFile("deployments/goerli.env", deploymentInfo);
        console.log("Deployment addresses saved to deployments/goerli.env");
    }
}