// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {BaseSetup} from "./BaseSetup.s.sol";
import {OwnableProjectList} from "../src/projects/OwnableProjectList.sol";
import {ProjectSupport} from "../src/OsmoticPool.sol";
import {Project} from "../src/interfaces/IProjectList.sol";

contract BaseSetUpWithProjectList is BaseSetup {
    OwnableProjectList ownedList;

    address listOwner = address(3);

    uint160 addressBase = 1000;

    uint256[] projectIds;

    string ownedListName = "ownedListName";
    bytes contenthash = bytes("QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm");

    function setUp() public virtual override {
        super.setUp();

        vm.prank(listOwner);
        ownedList = OwnableProjectList(controller.createProjectList(ownedListName));

        vm.label(listOwner, "listOwner");
    }

    function createProject() internal returns (uint256 projectId) {
        address beneficiary = createAddress(projectIds.length + 1);

        projectId = registry.registrerProject(beneficiary, contenthash);

        projectIds.push(projectId);
    }

    function createProjects(uint256 _numProjects) internal {
        for (uint256 i = projectIds.length; i < _numProjects; i++) {
            createProject();
        }
    }

    function supportProject(address _account, uint256 _projectId, int256 _supportDelta) internal {
        ProjectSupport[] memory participantSupports = new ProjectSupport[](1);
        participantSupports[0] = ProjectSupport(_projectId, _supportDelta);

        vm.prank(_account);
        pool.supportProjects(participantSupports);
    }

    function supportAllProjects(address _account, int256 _supportDelta) internal {
        ProjectSupport[] memory participantSupports = new ProjectSupport[](pool.MAX_ACTIVE_PROJECTS());

        for (uint256 i = 0; i < projectIds.length; i++) {
            participantSupports[i] = ProjectSupport(projectIds[i], _supportDelta);
        }

        vm.prank(_account);
        pool.supportProjects(participantSupports);
    }

    function activateAllProjects() internal {
        for (uint256 i = 0; i < projectIds.length; i++) {
            pool.activateProject(projectIds[i]);
        }
    }

    function getProject(uint256 _index) internal view returns (Project memory) {
        Project memory project = registry.getProject(projectIds[_index]);

        return project;
    }

    function createAddress(uint256 _offset) private view returns (address) {
        return address(addressBase + uint160(_offset));
    }
}
