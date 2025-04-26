// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";
import {Seaport} from "seaport-zksync/src/contracts/reference-seaport-1.6/Seaport.sol";

// Simple factory for complex contract deployment
contract SeaportFactoryMinimal {
    function deploySeaport(address conduitController) external returns (address) {
        return address(new Seaport(conduitController));
    }
}

contract SeaportDeployer is Script, TestExt {
    address private constant CONDUIT_CONTROLLER = 0xF4139bc44FE0084af8eb3Ac9d5b7b77AF0a5b071;
    
    Seaport public seaport;

// First transaction: deploy just the factory
function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

    // Encode paymaster input
    bytes memory paymaster_encoded_input = abi.encodeWithSelector(
        bytes4(keccak256("general(bytes)")),
        bytes("0x")
    );
    vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
    

    SeaportFactoryMinimal factory = new SeaportFactoryMinimal();
    console.log("Factory deployed at:", address(factory));
    vm.stopBroadcast();
}

// // Second transaction: use factory to deploy Seaport
// function run2() public {
//     vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
//     SeaportFactoryMinimal factory = SeaportFactoryMinimal(/* address from first tx */);
//     address seaportAddress = factory.deploySeaport(CONDUIT_CONTROLLER);
//     console.log("Seaport deployed at:", seaportAddress);
//     vm.stopBroadcast();
// }
}