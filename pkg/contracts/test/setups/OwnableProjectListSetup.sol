// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {BaseSetup} from "./BaseSetup.sol";

import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";
import {OwnableProjectList} from "../../src/projects/OwnableProjectList.sol";

contract OwnableProjectListSetup is BaseSetup {
    OwnableProjectList ownedList;
    ProjectRegistry projectRegistry;

    address listOwner = makeAddr("listOwner");
    address notListOwner = makeAddr("notListOwner");

    uint256 projectId;

    function setUp() public virtual override {
        super.setUp();

        (, address projectRegistryAddress) = createProjectRegistry(VERSION);
        projectRegistry = ProjectRegistry(projectRegistryAddress);

        vm.prank(listOwner);
        address ownedListAddress = createOwnableProjectList(projectRegistryAddress, "ownedList");
        ownedList = OwnableProjectList(ownedListAddress);

        projectId = createProjectInRegistry(projectRegistry);
    }

    function _addProject(uint256 _projectId) internal {
        vm.prank(listOwner);
        ownedList.addProject(_projectId);
    }

    function _removeProject(uint256 _projectId) internal {
        vm.prank(listOwner);
        ownedList.removeProject(_projectId);
    }
}
