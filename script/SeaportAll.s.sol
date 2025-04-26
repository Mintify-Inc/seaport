// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Seaport} from "../contracts/Seaport.sol";
import {ConduitController} from "../contracts/conduit/ConduitController.sol";
import {TestExt} from "lib/forge-zksync-std/src/TestExt.sol";

contract SeaportDeployer is Script, TestExt {
    Seaport public seaport;
    ConduitController public conduitController;
    address public create2Factory;
    address public seaportAddress;
    address public conduitControllerAddress;

    function setUp() public {
        // Hardcoded CREATE2 factory address - should be the same across all EVM chains
        create2Factory = 0x0000000000FFe8B47B3e2130213B802212439497;
    }

    function run() public {
        vm.startBroadcast();

        // Encode paymaster input
        bytes memory paymaster_encoded_input = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("0x")
        );
        vmExt.zkUsePaymaster(vm.envAddress("PAYMASTER_ADDRESS"), paymaster_encoded_input);
        
        // 1. Deploy the CREATE2 Factory if it doesn't exist
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sload(create2Factory.slot))
        }
        
        if (codeSize == 0) {
            console.log("Deploying CREATE2 Factory...");
            // This is the standard deployment bytecode for the CREATE2 factory
            bytes memory initCode = hex"604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";
            
            address deployedFactory;
            assembly {
                deployedFactory := create(0, add(initCode, 0x20), mload(initCode))
            }
            
            require(deployedFactory == create2Factory, "CREATE2 factory deployment failed");
            console.log("CREATE2 Factory deployed at:", create2Factory);
        } else {
            console.log("CREATE2 Factory already exists at:", create2Factory);
        }
        
        // 2. Deploy ConduitController with CREATE2 for deterministic address
        bytes32 conduitControllerSalt = keccak256(abi.encodePacked("ConduitController"));
        bytes memory conduitControllerInitCode = abi.encodePacked(type(ConduitController).creationCode);
        
        // Use CREATE2 to deploy ConduitController
        (bool success, bytes memory returnData) = create2Factory.call(
            abi.encodePacked(conduitControllerSalt, conduitControllerInitCode)
        );
        
        require(success, "ConduitController deployment failed");
        conduitControllerAddress = abi.decode(returnData, (address));
        conduitController = ConduitController(conduitControllerAddress);
        console.log("ConduitController deployed at:", conduitControllerAddress);
        
        // 3. Deploy Seaport with CREATE2 for deterministic address
        bytes32 seaportSalt = keccak256(abi.encodePacked("Seaport"));
        bytes memory seaportInitCode = abi.encodePacked(
            type(Seaport).creationCode, 
            abi.encode(conduitControllerAddress)
        );
        
        // Use CREATE2 to deploy Seaport
        (success, returnData) = create2Factory.call(
            abi.encodePacked(seaportSalt, seaportInitCode)
        );
        
        require(success, "Seaport deployment failed");
        seaportAddress = abi.decode(returnData, (address));
        seaport = Seaport(seaportAddress);
        console.log("Seaport deployed at:", seaportAddress);
        
        // 4. Optional: Create a conduit if needed
        // bytes32 conduitKey = bytes32(uint256(uint160(address(this))) << 96);
        // console.log("Creating conduit with key:", vm.toString(conduitKey));
        // conduitController.createConduit(conduitKey, address(this));
        // address conduit = conduitController.getConduit(conduitKey);
        // console.log("Conduit created at:", conduit);

        vm.stopBroadcast();
    }
}