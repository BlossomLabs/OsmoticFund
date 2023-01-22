// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IProjectList, Project, ProjectNotInList} from "../../interfaces/IProjectList.sol";

contract UnionProjectList is IProjectList {
    IProjectList[] public projectLists;

    constructor(IProjectList[] memory _projectLists) {
        projectLists = _projectLists;
    }

    function projectExists(uint256 _projectId) public view returns (bool) {
        for (uint256 i = 0; i < projectLists.length; i++) {
            if (projectLists[i].projectExists(_projectId)) {
                return true;
            }
        }

        return false;
    }

    function getProject(uint256 _projectId) external view returns (Project memory) {
        for (uint256 i = 0; i < projectLists.length; i++) {
            if (projectLists[i].projectExists(_projectId)) {
                return projectLists[i].getProject(_projectId);
            }
        }

        revert ProjectNotInList(_projectId);
    }
}
