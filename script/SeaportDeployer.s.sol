// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import { Seaport } from "seaport-core/src/Seaport.sol";
import { MintifyExchange } from "./../contracts/MintifyExchange.sol";

interface ImmutableCreate2Factory {
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode
    ) external payable returns (address deploymentAddress);
}

// NOTE: This script assumes that the CREATE2-related contracts have already been deployed.
contract SeaportDeployer is Script {
    ImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);
    address private constant CONDUIT_CONTROLLER =
        0x00000000F9490004C11Cef243f5400493c00Ad63;
    address private constant SEAPORT_ADDRESS =
        0x002c4B701a0cBece46B6A61441000d160d32CD4b;

    function run() public {
        // Utilizes the locally-defined PRIVATE_KEY environment variable to sign txs.
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // CREATE2 salt (20-byte caller or zero address + 12-byte salt).
        bytes32 salt = 0x0000000000000000000000000000000000000000ab822ab2ebc89c24dffa7f90;

        // Packed and ABI-encoded contract bytecode and constructor arguments.
        // NOTE: The Seaport contract *must* be compiled using the optimized profile config.
        bytes memory initCode = abi.encodePacked(
            type(MintifyExchange).creationCode,
            abi.encode(CONDUIT_CONTROLLER)
        );

        // Deploy the Seaport contract via ImmutableCreate2Factory.
        address seaport = IMMUTABLE_CREATE2_FACTORY.safeCreate2(salt, initCode);

        // Verify that the deployed contract address matches what we're expecting.
        assert(seaport == SEAPORT_ADDRESS);

        vm.stopBroadcast();
    }
}
