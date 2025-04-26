// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";

import { Seaport } from "seaport/contracts/Seaport.sol";

interface ImmutableCreate2Factory {
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode
    ) external payable returns (address deploymentAddress);
}

// NOTE: This script assumes that the CREATE2-related contracts have already been deployed.
contract SeaportDeployer is Script, TestExt {
    ImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000000000000000000000000000010000);
    address private constant CONDUIT_CONTROLLER =
        0xF4139bc44FE0084af8eb3Ac9d5b7b77AF0a5b071;
    address private constant SEAPORT_ADDRESS =
        0xDF3969A315e3fC15B89A2752D0915cc76A5bd82D;

    function run() public {
        // Utilizes the locally-defined PRIVATE_KEY environment variable to sign txs.
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
       

        // CREATE2 salt (20-byte caller or zero address + 12-byte salt).
        bytes32 salt = 0x0000000000000000000000000000000000000000d4b6fcc21169b803f25d2210;

        // Packed and ABI-encoded contract bytecode and constructor arguments.
        // NOTE: The Seaport contract *must* be compiled using the optimized profile config.
        bytes memory initCode = abi.encodePacked(
            type(Seaport).creationCode,
            abi.encode(CONDUIT_CONTROLLER)
        );

        // Deploy the Seaport contract via ImmutableCreate2Factory.
        address seaport = IMMUTABLE_CREATE2_FACTORY.safeCreate2(salt, initCode);

        // Verify that the deployed contract address matches what we're expecting.
        assert(seaport == SEAPORT_ADDRESS);

        vm.stopBroadcast();
    }
}
