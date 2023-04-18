// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableProjectListSetup} from "../setups/OwnableProjectListSetup.sol";

import {ProjectAlreadyInList, ProjectDoesNotExist, ProjectNotInList} from "../../src/interfaces/IProjectList.sol";

contract OwnableProjectListRemoveProject is OwnableProjectListSetup {
    event ListUpdated(uint256 indexed projectId, bool included);

    function setUp() public override {
        super.setUp();

        _addProject(projectId);
    }

    function test_RemoveProject() public {
        vm.expectEmit(true, true, true, true);
        emit ListUpdated(projectId, false);

        vm.prank(listOwner);
        ownedList.removeProject(projectId);

        assertFalse(ownedList.projectExists(projectId));
    }

    function test_RevertWhen_RemovingProjectAsNotListOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notListOwner);
        ownedList.removeProject(projectId);
    }

    function test_RevertWhen_RemovingUnregisteredProject() public {
        uint256 nonExistingProjectId = 9999;

        vm.expectRevert(abi.encodeWithSelector(ProjectDoesNotExist.selector, nonExistingProjectId));
        _removeProject(nonExistingProjectId);
    }

    function test_RevertWhen_RemovingProjectNotInList() public {
        uint256 projectNotInListId = createProjectInRegistry(projectRegistry);

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, projectNotInListId));
        _removeProject(projectNotInListId);
    }
}
