// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MintifyExchange } from "../contracts/MintifyExchange.sol";

contract DeterministicDeployFactory {
    event Deploy(address addr);
    address addr;

    function generateAddr(bytes memory bytecode, uint _salt) private {
        address addr2;
        assembly {
            addr2 := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr2)) {
                revert(0, 0)
            }
        }

        addr = addr2;
        emit Deploy(addr);
    }

    function run() public returns (address _addr) {
       generateAddr(type(MintifyExchange).creationCode, 0);
       return addr;
    }
}