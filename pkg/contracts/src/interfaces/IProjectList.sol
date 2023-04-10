// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ProjectAlreadyInList(uint256 projectId);
error ProjectDoesNotExist(uint256 projectId);
error ProjectNotInList(uint256 projectId);

struct Project {
    address admin;
    address beneficiary;
    bytes contenthash;
}

interface IProjectList {
    function getProject(uint256 _projectId) external view returns (Project memory);
    function projectExists(uint256 _projectId) external view returns (bool);
}
