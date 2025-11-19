// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorkNFT} from "../src/Mintwork_NFT.sol";

/**
 * @title DeployWorkNFT
 * @dev Deployment script for the WorkNFT contract
 * 
 * Usage:
 * forge script script/DeployWorkNFT.s.sol:DeployWorkNFT --rpc-url <RPC_URL> --broadcast --verify
 * 
 * For local testing:
 * forge script script/DeployWorkNFT.s.sol:DeployWorkNFT
 */
contract DeployWorkNFT is Script {
    function run() external returns (WorkNFT) {
        // Get the deployer's address from the private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying WorkNFT contract...");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy WorkNFT with deployer as initial owner
        WorkNFT workNFT = new WorkNFT(deployer);
        
        vm.stopBroadcast();
        
        console.log("WorkNFT deployed at:", address(workNFT));
        console.log("Owner:", workNFT.owner());
        console.log("Name:", workNFT.name());
        console.log("Symbol:", workNFT.symbol());
        
        return workNFT;
    }
}

