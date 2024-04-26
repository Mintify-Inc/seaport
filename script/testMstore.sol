// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";



contract TestMstore is Script {
function _name() internal pure  returns (string memory) {
    // Return the name of the contract.
    assembly {
        mstore(0x20, 0x20) // Set the length of the string "Mintify", which is 7 characters.
        mstore(0x47, 0x074d696e74696679)
        return(0x20, 0x60)
    }
}

    function run() public returns (string memory) {
        return _name();
    }
}
