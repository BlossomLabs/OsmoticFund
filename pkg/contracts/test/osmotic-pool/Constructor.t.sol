// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {OsmoticPool} from "../../src/OsmoticPool.sol";

contract OsmoticPoolConstructor is Test {
    address cfaForwarder = makeAddr("cfaForwarder");
    address osmoticController = makeAddr("osmoticController");

    function test_Constructor() public {
        OsmoticPool osmoticPool = new OsmoticPool(cfaForwarder, osmoticController);

        assertEq(osmoticPool.cfaForwarder(), cfaForwarder, "CFA forwarder mismatch");
        assertEq(osmoticPool.controller(), osmoticController, "Controller mismatch");
    }

    function test_RevertWhen_InstantiatingWithNoCFAForwarder() public {
        vm.expectRevert("Zero CFA Forwarder");
        new OsmoticPool(address(0), osmoticController);
    }

    function test_RevertWhen_InstantiatingWithNoController() public {
        vm.expectRevert("Zero Controller");
        new OsmoticPool(cfaForwarder, address(0));
    }
}
