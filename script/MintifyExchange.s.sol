// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/MintifyExchange.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);

        MintifyExchange mintifyExchange = new MintifyExchange(0x00000000F9490004C11Cef243f5400493c00Ad63);

        vm.stopBroadcast();
    }
}