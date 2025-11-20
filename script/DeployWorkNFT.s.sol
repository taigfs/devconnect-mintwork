// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorkNFT} from "../src/Mintwork_NFT.sol";
import {WorkMarketplace} from "../src/Mintwork_Escrow.sol";

/**
 * @title DeployMintwork
 * @dev Deployment script for WorkNFT and WorkMarketplace contracts
 * 
 * Usage:
 * forge script script/DeployWorkNFT.s.sol:DeployMintwork --rpc-url <RPC_URL> --broadcast --verify
 * 
 * For local testing:
 * forge script script/DeployWorkNFT.s.sol:DeployMintwork
 * 
 * Environment variables required:
 * - PRIVATE_KEY: Deployer's private key
 * - WETH_ADDRESS: WETH contract address on the target network
 *   Scroll Sepolia: 0x5300000000000000000000000000000000000004
 */
contract DeployMintwork is Script {
    function run() external returns (WorkNFT workNft, WorkMarketplace marketplace) {
        // Get the deployer's address from the private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get WETH address from environment variable
        address wethAddress = vm.envAddress("WETH_ADDRESS");
        
        console.log("========================================");
        console.log("Deploying Mintwork Contracts...");
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("WETH address:", wethAddress);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy WorkNFT with deployer as initial owner
        console.log("Step 1: Deploying WorkNFT...");
        workNft = new WorkNFT(deployer);
        console.log("  WorkNFT deployed at:", address(workNft));
        console.log("  Name:", workNft.name());
        console.log("  Symbol:", workNft.symbol());
        console.log("  Initial Owner:", workNft.owner());
        console.log("");
        
        // Step 2: Deploy WorkMarketplace with WETH and WorkNFT addresses
        console.log("Step 2: Deploying WorkMarketplace...");
        marketplace = new WorkMarketplace(wethAddress, address(workNft));
        console.log("  WorkMarketplace deployed at:", address(marketplace));
        console.log("  WETH:", address(marketplace.WETH()));
        console.log("  WorkNFT:", address(marketplace.WORK_NFT()));
        console.log("  Owner:", marketplace.owner());
        console.log("");
        
        // Step 3: Transfer WorkNFT ownership to WorkMarketplace
        console.log("Step 3: Transferring WorkNFT ownership to WorkMarketplace...");
        workNft.transferOwnership(address(marketplace));
        console.log("  New WorkNFT Owner:", workNft.owner());
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("Deployment Complete!");
        console.log("========================================");
        console.log("WorkNFT:", address(workNft));
        console.log("WorkMarketplace:", address(marketplace));
        console.log("========================================");
        
        return (workNft, marketplace);
    }
}

