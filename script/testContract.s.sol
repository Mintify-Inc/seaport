// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/TestNFT.sol";

contract LevenCanyonLookoutTest is Test {
    LevenCanyonLookout private levenCanyonLookout;
    address private user = address(0x1234);

    function setUp() public {
        levenCanyonLookout = new LevenCanyonLookout();
        vm.deal(user, 1 ether); // fund the user with ETH
        // set any other parameters as needed
        levenCanyonLookout.setStartTimePhase1(0);
        // levenCanyonLookout.setPricePhase1(2600000000000000); // 0.0026 ETH
        // levenCanyonLookout.setLaunchpadFee(370000000000000); // 0.00037 ETH
    }

    function testMintPhase1() public {
        vm.startPrank(user);
        // Attempt to mint with exactly 0.00297 ETH
        levenCanyonLookout.mintPhase1{value: 2970000000000000}(1);
        vm.stopPrank();

        // Assertions
        assertEq(levenCanyonLookout.totalSupply(), 1);
    }
}