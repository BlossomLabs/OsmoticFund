// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";

import {IProjectList, ProjectNotInList, Project} from "../interfaces/IProjectList.sol";
import {ProjectRegistry, ProjectDoesNotExist} from "./ProjectRegistry.sol";

error ProjectNotIncluded(uint256 projectId);
error ProjectAlreadyIncluded(uint256 projectId);

contract OwnableProjectList is Ownable {
    ProjectRegistry public projectRegistry;
    mapping(uint256 => bool) public projectsIncluded;

    modifier projectExists(uint256 _projectId) {
        if (!projectRegistry.projectExists(_projectId)) {
            revert ProjectDoesNotExist(_projectId);
        }

        _;
    }

    constructor(ProjectRegistry _projectRegistry) Ownable() {
        projectRegistry = _projectRegistry;
    }

    function addProject(uint256 _projectId) public onlyOwner projectExists(_projectId) {
        if (projectsIncluded[_projectId]) {
            revert ProjectAlreadyIncluded(_projectId);
        }

        projectsIncluded[_projectId] = true;
    }

    function removeProject(uint256 _projectId) public onlyOwner projectExists(_projectId) {
        if (!projectsIncluded[_projectId]) {
            revert ProjectNotIncluded(_projectId);
        }

        projectsIncluded[_projectId] = false;
    }

    function addProjects(uint256[] calldata _projectIds) external onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            addProject(projectId);
        }
    }

    function removeProjects(uint256[] calldata _projectIds) external onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            removeProject(projectId);
        }
    }
}
