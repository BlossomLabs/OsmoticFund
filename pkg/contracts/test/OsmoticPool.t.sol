// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";
import {
    OsmoticPool,
    ProjectSupport,
    PoolProject,
    ProjectAlreadyActive,
    ProjectNeedsMoreStake,
    ProjectWithoutSupport
} from "../src/OsmoticPool.sol";
import {OsmoticParams} from "../src/OsmoticFormula.sol";
import {ProjectNotInList} from "../src/interfaces/IProjectList.sol";
import {BaseSetUpWithProjectList} from "../script/BaseSetUpWithProjectList.s.sol";

contract OsmoticPoolTest is Test, BaseSetUpWithProjectList {
    using ABDKMath64x64 for int128;

    event OsmoticParamsChanged(uint256 decay, uint256 drop, uint256 maxFlow, uint256 minStakeRatio);
    event ProjectSupportUpdated(uint256 indexed projectId, address participant, int256 delta);

    OsmoticParams osmoticParams = OsmoticParams(1, 1, 1, 1);
    address noTokenHolder = address(10);
    address governanceTokenHolder = address(100);
    uint256 stakedAmount = 100e18;

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);

    function setUp() public override {
        super.setUp();
    }

    function testActivateProject() public {
        uint256 projectId = createProject();
        (,, bool activeBefore,) = pool.poolProjects(projectId);
        assertFalse(activeBefore);

        supportProject(mimeHolder0, projectId, 10);
        vm.expectEmit(true, false, false, false);
        emit ProjectActivated(projectId);

        pool.activateProject(projectId);
        (,, bool activeAfter,) = pool.poolProjects(projectId);

        assertTrue(activeAfter);
    }

    function testActivateProjectHavingToDesactiveAnotherOne() public {
        createProjects(pool.MAX_ACTIVE_PROJECTS());

        supportAllProjects(mimeHolder0, 20);
        activateAllProjects();

        uint256 newProjectId = createProject();
        supportProject(mimeHolder0, newProjectId, 30);

        uint256 deactivatedProjectId = projectIds[0];
        vm.expectEmit(true, false, false, false);
        emit ProjectDeactivated(deactivatedProjectId);

        pool.activateProject(newProjectId);
        (,, bool active,) = pool.poolProjects(deactivatedProjectId);
        assertFalse(active);
    }

    function testActivateProjectNotInList() public {
        uint256 nonExistentProject = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, nonExistentProject));
        pool.activateProject(nonExistentProject);
    }

    function testActivateProjectWithoutSupport() public {
        uint256 projectId = createProject();

        vm.expectRevert(abi.encodeWithSelector(ProjectWithoutSupport.selector, projectId));
        pool.activateProject(projectId);
    }

    function testActivateAlreadyActivedProject() public {
        uint256 projectId = createProject();
        supportProject(mimeHolder0, projectId, 10);
        pool.activateProject(projectId);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyActive.selector, projectId));
        pool.activateProject(projectId);
    }

    function testActivateProjectWithNotEnoughStake() public {
        createProjects(pool.MAX_ACTIVE_PROJECTS());

        int256 minSupportRequired = 20;

        supportAllProjects(mimeHolder0, minSupportRequired);
        activateAllProjects();

        uint256 projectId = createProject();
        int256 projectSupport = 10;
        supportProject(mimeHolder0, projectId, 10);

        vm.expectRevert(
            abi.encodeWithSelector(ProjectNeedsMoreStake.selector, projectId, projectSupport, minSupportRequired)
        );
        pool.activateProject(projectId);
    }
}
