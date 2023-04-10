// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";

contract Dummy {}

contract OsmoticControllerConstructor is Test {
    uint256 version = 1;
    address dummyContract;
    address projectRegistry = makeAddr("projectRegistry");
    address mimeTokenFactory = makeAddr("mimeTokenFactory");

    function setUp() public {
        dummyContract = address(new Dummy());
    }

    function test_Constructor() public {
        OsmoticController controller = new OsmoticController(version, dummyContract, projectRegistry, mimeTokenFactory);

        assertEq(controller.version(), version, "version mismatch");
        assertEq(controller.claimTimestamp(), block.timestamp, "claim timestamp mismatch");
        assertEq(controller.projectRegistry(), projectRegistry, "project registry mismatch");
        assertEq(controller.mimeTokenFactory(), mimeTokenFactory, "version mismatch");
    }
}
