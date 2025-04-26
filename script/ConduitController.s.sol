// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";

import { Seaport } from "seaport-core/src/Seaport.sol";

contract SeaportDeployer is Script, TestExt {
    
    address private constant CONDUIT_CONTROLLER = 0x1972ddFa941670A9F5fa2A0094f4490347B99D7B;
    address private constant SEAPORT_ADDRESS = 0xDF3969A315e3fC15B89A2752D0915cc76A5bd82D;

    Seaport public seaport;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
        seaport = new Seaport(CONDUIT_CONTROLLER);

        // Output the address of the deployed contract
        console.log("Seaport deployed to:", address(seaport));

        vm.stopBroadcast();
    }

}