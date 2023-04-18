// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableProjectListSetup} from "../setups/OwnableProjectListSetup.sol";

import {ProjectAlreadyInList, ProjectDoesNotExist} from "../../src/interfaces/IProjectList.sol";

contract OwnableProjectListAddProject is OwnableProjectListSetup {
    event ListUpdated(uint256 indexed projectId, bool included);

    function test_AddProject() public {
        vm.expectEmit(true, true, true, true);
        emit ListUpdated(projectId, true);

        _addProject(projectId);

        assertTrue(ownedList.projectExists(projectId), "project not included");
    }

    function test_RevertWhen_AddingProjectAsNotListOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notListOwner);
        ownedList.addProject(projectId);
    }

    function test_RevertWhen_AddingUnregisteredProject() public {
        uint256 nonExistingProjectId = 9999;

        vm.expectRevert(abi.encodeWithSelector(ProjectDoesNotExist.selector, nonExistingProjectId));
        _addProject(nonExistingProjectId);
    }

    function test_RevertWhen_AddingProjectAlreadyInList() public {
        _addProject(projectId);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyInList.selector, projectId));
        _addProject(projectId);
    }
}
