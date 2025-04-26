// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ZkCreate2Factory} from "../contracts/ZkCreate2Factory.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";

contract CounterScript is Script, TestExt {
    ZkCreate2Factory public create2Factory;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
        create2Factory = new ZkCreate2Factory();

        vm.stopBroadcast();
    }


    //cast publish --rpc-url sophon --private-key $PRIVATE_KEY 0xf87e8085174876e800830186a08080ad601f80600e600039806000f350fe60003681823780368234f58015156014578182fd5b80825250506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222

}