// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ZkCreate2Factory {
    event Deployed(address addr, bytes32 salt);

    // This is a zkSync-compatible implementation that avoids assembly create2
    function deploy(bytes32 salt, bytes memory bytecode) public returns (address) {
        // Use the create2 opcode at the Solidity level, not assembly level
        address addr = address(new DeploymentProxy{salt: salt}(bytecode));
        emit Deployed(addr, salt);
        return addr;
    }
}

// Helper contract that gets created via create2 and immediately deploys the target contract
contract DeploymentProxy {
    constructor(bytes memory _code) {
        // Copy the bytecode to memory and deploy it
        address addr;
        assembly {
            addr := create(0, add(_code, 0x20), mload(_code))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}