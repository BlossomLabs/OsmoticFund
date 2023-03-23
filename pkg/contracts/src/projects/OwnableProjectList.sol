// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";

import {IProjectList, Project, ProjectNotInList} from "../interfaces/IProjectList.sol";

import {ProjectRegistry} from "./ProjectRegistry.sol";

error ProjectDoesNotExist(uint256 projectId);
error ProjectAlreadyInList(uint256 projectId);

contract OwnableProjectList is Ownable, IProjectList {
    string public name;
    ProjectRegistry public projectRegistry;

    mapping(uint256 => bool) internal isProjectIncluded;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ListUpdated(uint256 indexed projectId, bool included);

    /* *************************************************************************************************************************************/
    /* ** Modifiers                                                                                                                      ***/
    /* *************************************************************************************************************************************/

    modifier isValidProject(uint256 _projectId) {
        if (projectRegistry.projectExists(_projectId)) {
            _;
        } else {
            revert ProjectDoesNotExist(_projectId);
        }
    }

    constructor(address _projectRegistry, string memory _name) {
        projectRegistry = ProjectRegistry(_projectRegistry);
        name = _name;
    }

    /* *************************************************************************************************************************************/
    /* ** Project Functions                                                                                                              ***/
    /* *************************************************************************************************************************************/

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

    /* *************************************************************************************************************************************/
    /* ** IProjectList Functions                                                                                                         ***/
    /* *************************************************************************************************************************************/

    function getProject(uint256 _projectId) public view returns (Project memory) {
        if (isProjectIncluded[_projectId]) {
            return projectRegistry.getProject(_projectId);
        }
        revert ProjectNotInList(_projectId);
    }

    function projectExists(uint256 _projectId) public view returns (bool) {
        return isProjectIncluded[_projectId];
    }
}
