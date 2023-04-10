// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableProjectListSetup} from "../setups/OwnableProjectListSetup.sol";

import {Project, ProjectNotInList} from "../../src/interfaces/IProjectList.sol";

contract OwnableProjectListGetProject is OwnableProjectListSetup {
    function test_GetProject() public {
        _addProject(projectId);

        Project memory expectedProject = projectRegistry.getProject(projectId);
        Project memory project = ownedList.getProject(projectId);

        assertEq(project.admin, expectedProject.admin, "project admin mismatch");
        assertEq(project.beneficiary, expectedProject.beneficiary, "project beneficiary mismatch");
        assertEq(project.contenthash, expectedProject.contenthash, "project contenthash mismatch");
    }

    function test_RevertWhen_GettingProjectNotInList() public {
        uint256 nonExistingProjectId = 9999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, nonExistingProjectId));
        ownedList.getProject(nonExistingProjectId);
    }
}
