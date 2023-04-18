// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticPoolSetup} from "../setups/OsmoticPoolSetup.sol";

import {ProjectAlreadyActive, ProjectNeedsMoreStake, ProjectNotInList} from "../../src/OsmoticPool.sol";

contract OsmoticPoolActivateProject is OsmoticPoolSetup {
    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);

    function test_ActivateProject() public {
        uint256 projectId = _createProject();
        (,, bool activeBefore,) = pool.poolProjects(projectId);
        assertFalse(activeBefore);

        _supportProject(MIME_HOLDER0, projectId, 10 ether);
        vm.expectEmit(true, false, false, false);
        emit ProjectActivated(projectId);

        pool.activateProject(projectId);
        (,, bool activeAfter,) = pool.poolProjects(projectId);

        assertTrue(activeAfter);
    }

    function test_ActivateProjectHavingToDesactiveAnotherOne() public {
        _createProjects(pool.MAX_ACTIVE_PROJECTS());

        _supportAllProjects(MIME_HOLDER0, 20 ether);
        _activateAllProjects();

        uint256 newProjectId = _createProject();
        _supportProject(MIME_HOLDER0, newProjectId, 30 ether);

        uint256 deactivatedProjectId = projectIds[0];
        vm.expectEmit(true, false, false, false);
        emit ProjectDeactivated(deactivatedProjectId);

        pool.activateProject(newProjectId);

        (uint256 flowLastRate,, bool active,) = pool.poolProjects(deactivatedProjectId);
        assertFalse(active);
        assertEq(flowLastRate, 0);
    }

    function test_RevertWhenActivatingProjectNotInList() public {
        uint256 nonExistentProject = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, nonExistentProject));
        pool.activateProject(nonExistentProject);
    }

    function test_RevertWhenActivatingAlreadyActivedProject() public {
        uint256 projectId = _createProject();
        _supportProject(MIME_HOLDER0, projectId, 10 ether);
        pool.activateProject(projectId);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyActive.selector, projectId));
        pool.activateProject(projectId);
    }

    function test_RevertWhenActivatingProjectWithNotEnoughStake() public {
        _createProjects(pool.MAX_ACTIVE_PROJECTS());

        int256 minSupportRequired = 20 ether;

        _supportAllProjects(MIME_HOLDER0, minSupportRequired);
        _activateAllProjects();

        uint256 projectId = _createProject();
        int256 projectSupport = 10 ether;
        _supportProject(MIME_HOLDER0, projectId, 10 ether);

        vm.expectRevert(
            abi.encodeWithSelector(ProjectNeedsMoreStake.selector, projectId, projectSupport, minSupportRequired)
        );
        pool.activateProject(projectId);
    }
}
