// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";

import {IProjectList, Project, ProjectNotInList} from "../../src/interfaces/IProjectList.sol";

import {ProjectRegistry, ProjectDoesNotExist} from "./ProjectRegistry.sol";

error ProjectAlreadyInList(uint256 projectId);

contract OwnableProjectList is Ownable, IProjectList {
    string public name;
    ProjectRegistry public projectRegistry;

    mapping(uint256 => bool) public isProjectIncluded;

    event ListUpdated(uint256 indexed projectId, bool included);

    modifier isValidProject(uint256 _projectId) {
        if (!projectRegistry.projectExists(_projectId)) {
            revert ProjectDoesNotExist(_projectId);
        }

        _;
    }

    constructor(address _projectRegistry, string memory _name) Ownable() {
        projectRegistry = ProjectRegistry(_projectRegistry);
        name = _name;
    }

    function addProject(uint256 _projectId) public onlyOwner isValidProject(_projectId) {
        if (isProjectIncluded[_projectId]) {
            revert ProjectAlreadyInList(_projectId);
        }

        isProjectIncluded[_projectId] = true;

        emit ListUpdated(_projectId, true);
    }

    function removeProject(uint256 _projectId) public onlyOwner isValidProject(_projectId) {
        if (!isProjectIncluded[_projectId]) {
            revert ProjectNotInList(_projectId);
        }

        isProjectIncluded[_projectId] = false;

        emit ListUpdated(_projectId, false);
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

    function getProject(uint256 _projectId) public view returns (Project memory) {
        if (!isProjectIncluded[_projectId]) {
            revert ProjectNotInList(_projectId);
        }
        return projectRegistry.getProject(_projectId);
    }

    function projectExists(uint256 _projectId) public view returns (bool) {
        return isProjectIncluded[_projectId];
    }
}
