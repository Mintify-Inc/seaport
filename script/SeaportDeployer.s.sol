// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";
import {Seaport} from "seaport-zksync/src/contracts/reference-seaport-1.6/Seaport.sol";

interface ImmutableCreate2Factory {
    function create2(
        bytes32 salt,
        bytes32 bytecodeHash,
        bytes calldata constructorInput
    ) external payable returns (address deployedAddress);
}

contract SeaportDeployer is Script, TestExt {
    ImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000000000000000000000000000010000);
    address private constant CONDUIT_CONTROLLER =
        0xF4139bc44FE0084af8eb3Ac9d5b7b77AF0a5b071;
    address private constant EXPECTED_SEAPORT_ADDRESS =
        0xDF3969A315e3fC15B89A2752D0915cc76A5bd82D;
    
    Seaport public seaport; // Declare at contract level

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Encode paymaster input
        
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
       
        // Option 1: Direct deployment (More reliable on zkSync)
        console.log("Deploying Seaport directly with conduit controller:", CONDUIT_CONTROLLER);
        seaport = new Seaport(CONDUIT_CONTROLLER);
        console.log("Seaport deployed at:", address(seaport));

                
        // // Option 2: Using zkSync's system CREATE2 factory
        // console.log("Deploying via CREATE2 factory");
                    
        // // Get creation code without constructor args
        // bytes memory creationCode = type(Seaport).creationCode;
                    
        // // Hash the creation code
        // bytes32 bytecodeHash = keccak256(creationCode);
                    
        // // Create the salt - use a simple salt for testing
        // bytes32 salt = bytes32(uint256(0x1234));
                    
        // // Encode constructor arguments
        // bytes memory constructorArgs = abi.encode(CONDUIT_CONTROLLER);
                    
        // // Deploy using CREATE2 factory
        // seaport = new Seaport(CONDUIT_CONTROLLER);
        // console.log("Seaport deployed at:", address(seaport));

        // address deployedAddress = IMMUTABLE_CREATE2_FACTORY.create2(
        //     salt,
        //     bytecodeHash,
        //     constructorArgs
        // );
     
        // // seaport = Seaport(deployedAddress);
        // console.log("Seaport deployed at:", deployedAddress);
        

        vm.stopBroadcast();
    }
}