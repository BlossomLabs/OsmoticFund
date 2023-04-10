// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {OwnableProjectList} from "../../src/projects/OwnableProjectList.sol";

contract OwnableProjectListConstructor is Test {
    address projectRegistry = makeAddr("projectRegistry");
    string listName = "ownedList";

    function test_Constructor() public {
        OwnableProjectList ownedList = new OwnableProjectList(projectRegistry, listName);

        assertEq(ownedList.name(), listName, "name mismatch");
        assertEq(address(ownedList.projectRegistry()), projectRegistry, "project registry mismatch");
    }
}
