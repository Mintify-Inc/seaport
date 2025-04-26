// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Seaport} from "seaport-core/src/Seaport.sol";
import {ConduitController} from "seaport-core/src/conduit/ConduitController.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";

contract SeaportDeployer is Script, TestExt {
    Seaport public seaport;
    ConduitController public conduitController;
    address payable public seaportAddress;
    address public conduitControllerAddress;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
        
        // 2. Deploy ConduitController directly (zkSync prefers this)
        console.log("Deploying ConduitController...");
        conduitController = new ConduitController();
        conduitControllerAddress = address(conduitController);
        console.log("ConduitController deployed at:", conduitControllerAddress);
        
        // 3. Deploy Seaport directly (zkSync prefers this)
        // console.log("Deploying Seaport...");
        // seaport = new Seaport(conduitControllerAddress);
        // seaportAddress = payable(address(seaport));
        // console.log("Seaport deployed at:", seaportAddress);

        vm.stopBroadcast();
    }
}