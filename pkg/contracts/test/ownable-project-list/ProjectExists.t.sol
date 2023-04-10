// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableProjectListSetup} from "../setups/OwnableProjectListSetup.sol";

contract OwnableProjectListProjectExists is OwnableProjectListSetup {
    function test_ProjectExists() public {
        _addProject(projectId);

        assertTrue(ownedList.projectExists(projectId), "project should exist");
        assertFalse(ownedList.projectExists(9999), "project should not exist");
    }
}
