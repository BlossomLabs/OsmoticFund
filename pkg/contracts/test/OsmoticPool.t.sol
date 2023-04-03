// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";
import "@oz/utils/Strings.sol";

import {
    OsmoticPool,
    ProjectSupport,
    PoolProject,
    ProjectAlreadyActive,
    ProjectNeedsMoreStake,
    ProjectWithoutSupport,
    SupportUnderflow
} from "../src/OsmoticPool.sol";
import {OsmoticParams} from "../src/OsmoticFormula.sol";
import {ProjectNotInList} from "../src/interfaces/IProjectList.sol";
import {BaseSetUpWithProjectList} from "../script/BaseSetUpWithProjectList.s.sol";

contract OsmoticPoolTest is Test, BaseSetUpWithProjectList {
    using ABDKMath64x64 for int128;

    OsmoticParams osmoticParams = OsmoticParams(1, 1, 1, 1);
    address noTokenHolder = address(10);
    address governanceTokenHolder = address(100);
    uint256 stakedAmount = 100e18;

    uint256 projectId0;
    uint256 projectId1;

    OsmoticParams newOsmoticParams = OsmoticParams({decay: 1000, drop: 1001, maxFlow: 1002, minStakeRatio: 1003});

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);
    event OsmoticParamsChanged(uint256 decay, uint256 drop, uint256 maxFlow, uint256 minStakeRatio);

    function setUp() public override {
        super.setUp();

        projectId0 = createProject();
        projectId1 = createProject();
    }

    function test_SupportProjects() public {
        ProjectSupport[] memory projectSupports = new ProjectSupport[](2);

        projectSupports[0].projectId = projectId0;
        projectSupports[1].projectId = projectId1;

        projectSupports[0].deltaSupport = 20 ether;
        projectSupports[1].deltaSupport = 30 ether;

        _performProjectSupportTest(projectSupports);
    }

    function test_UnsupportProjects() public {
        int256 deltaSupport0 = 20 ether;
        int256 deltaSupport1 = 30 ether;

        supportProject(mimeHolder0, projectId0, deltaSupport0);
        supportProject(mimeHolder0, projectId1, deltaSupport1);

        ProjectSupport[] memory projectUnsupports = new ProjectSupport[](2);
        projectUnsupports[0].projectId = projectId0;
        projectUnsupports[0].deltaSupport = -10 ether;
        projectUnsupports[1].projectId = projectId1;
        projectUnsupports[1].deltaSupport = -15 ether;

        _performProjectSupportTest(projectUnsupports);
    }

    function test_SupportAndUnsupportProjectAtTheSameTime() public {
        string memory projectIdStr = Strings.toString(projectId0);
        ProjectSupport[] memory projectSupports = new ProjectSupport[](2);

        projectSupports[0].projectId = projectId0;
        projectSupports[1].projectId = projectId0;

        projectSupports[0].deltaSupport = 20 ether;
        projectSupports[1].deltaSupport = -10 ether;

        int256 newDeltaSupport = projectSupports[0].deltaSupport + projectSupports[1].deltaSupport;

        uint256 projectSupportBefore = pool.getProjectSupport(projectId0);
        uint256 participantSupportBefore = pool.getParticipantSupport(projectId0, mimeHolder0);

        vm.prank(mimeHolder0);
        pool.supportProjects(projectSupports);

        uint256 projectSupportAfter = pool.getProjectSupport(projectId0);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId0, mimeHolder0);

        uint256 expectedProjectSupport = uint256(int256(projectSupportBefore) + newDeltaSupport);
        uint256 expectedParticipantSupport = uint256(int256(participantSupportBefore) + newDeltaSupport);

        assertEq(
            projectSupportAfter,
            expectedProjectSupport,
            string.concat("Project ", projectIdStr, " total support mismatch")
        );
        assertEq(
            participantSupportAfter,
            expectedParticipantSupport,
            string.concat("Project ", projectIdStr, " participant support mismatch")
        );
    }

    function test_RevertWhenSupportingProjectsWithoutBalance() public {
        address invalidParticipant = address(999);

        vm.expectRevert("NO_BALANCE_AVAILABLE");
        supportProject(invalidParticipant, projectId0, 20 ether);
    }

    function test_RevertWhenSupportingInvalidProjects() public {
        uint256 invalidProjectId = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, invalidProjectId));
        supportProject(mimeHolder0, invalidProjectId, 20 ether);
    }

    function test_RevertWhenSupportingWithMoreThanAvailableBalance() public {
        uint256 holderBalance = mimeToken.balanceOf(mimeHolder0);

        vm.expectRevert("NOT_ENOUGH_BALANCE");
        supportProject(mimeHolder0, projectId0, int256(holderBalance + 1 ether));
    }

    function test_RevertWhenSupportingProjectsWithSupportUnderflow() public {
        int256 deltaSupport = 20 ether;
        supportProject(mimeHolder0, projectId0, deltaSupport);

        vm.expectRevert(abi.encodeWithSelector(SupportUnderflow.selector));
        supportProject(mimeHolder0, projectId0, -deltaSupport - 1 ether);
    }

    function test_ActivateProject() public {
        (,, bool activeBefore,) = pool.poolProjects(projectId0);
        assertFalse(activeBefore);

        supportProject(mimeHolder0, projectId0, 10);
        vm.expectEmit(true, false, false, false);
        emit ProjectActivated(projectId0);

        pool.activateProject(projectId0);
        (,, bool activeAfter,) = pool.poolProjects(projectId0);

        assertTrue(activeAfter);
    }

    function test_ActivateProjectHavingToDesactiveAnotherOne() public {
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

    function test_RevertWhenActivatingProjectNotInList() public {
        uint256 nonExistentProject = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, nonExistentProject));
        pool.activateProject(nonExistentProject);
    }

    function test_RevertWhenActivatingProjectwithoutSupport() public {
        vm.expectRevert(abi.encodeWithSelector(ProjectWithoutSupport.selector, projectId0));
        pool.activateProject(projectId0);
    }

    function test_RevertWhenActivatingAlreadyActivedProject() public {
        supportProject(mimeHolder0, projectId0, 10);
        pool.activateProject(projectId0);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyActive.selector, projectId0));
        pool.activateProject(projectId0);
    }

    function test_RevertWhenActivatingProjectWithNotEnoughStake() public {
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

    function test_SetOsmoticFormulaParams() public {
        vm.expectEmit(false, false, false, true);
        emit OsmoticParamsChanged(
            newOsmoticParams.decay, newOsmoticParams.drop, newOsmoticParams.maxFlow, newOsmoticParams.minStakeRatio
        );

        pool.setOsmoticFormulaParams(newOsmoticParams);

        _assertOsmoticParam(pool.decay(), newOsmoticParams.decay);
        _assertOsmoticParam(pool.drop(), newOsmoticParams.drop);
        _assertOsmoticParam(pool.maxFlow(), newOsmoticParams.maxFlow);
        _assertOsmoticParam(pool.minStakeRatio(), newOsmoticParams.minStakeRatio);
    }

    function test_setOsmoticFormulaDecay() public {
        vm.expectEmit(false, false, false, true);
        emit OsmoticParamsChanged(newOsmoticParams.decay, params.drop, params.maxFlow, params.minStakeRatio);

        pool.setOsmoticFormulaDecay(newOsmoticParams.decay);

        _assertOsmoticParam(pool.decay(), newOsmoticParams.decay);
    }

    function test_setOsmoticFormulaDrop() public {
        vm.expectEmit(false, false, false, true);
        emit OsmoticParamsChanged(params.decay, newOsmoticParams.drop, params.maxFlow, params.minStakeRatio);

        pool.setOsmoticFormulaDrop(newOsmoticParams.drop);

        _assertOsmoticParam(pool.drop(), newOsmoticParams.drop);
    }

    function test_setOsmoticFormulaMaxFlow() public {
        vm.expectEmit(false, false, false, true);
        emit OsmoticParamsChanged(params.decay, params.drop, newOsmoticParams.maxFlow, params.minStakeRatio);

        pool.setOsmoticFormulaMaxFlow(newOsmoticParams.maxFlow);

        _assertOsmoticParam(pool.maxFlow(), newOsmoticParams.maxFlow);
    }

    function test_setOsmoticFormulaMinStakeRatio() public {
        vm.expectEmit(false, false, false, true);
        emit OsmoticParamsChanged(params.decay, params.drop, params.maxFlow, newOsmoticParams.minStakeRatio);

        pool.setOsmoticFormulaMinStakeRatio(newOsmoticParams.minStakeRatio);

        _assertOsmoticParam(pool.minStakeRatio(), newOsmoticParams.minStakeRatio);
    }

    function _performProjectSupportTest(ProjectSupport[] memory _projectSupports) private {
        uint256[] memory projectTotalSupportsBefore = new uint256[](_projectSupports.length);
        uint256[] memory projectParticipantSupportsBefore = new uint256[](_projectSupports.length);

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            uint256 projectId = _projectSupports[i].projectId;
            int256 deltaSupport = _projectSupports[i].deltaSupport;

            projectTotalSupportsBefore[i] = pool.getProjectSupport(projectId);
            projectParticipantSupportsBefore[i] = pool.getParticipantSupport(projectId, mimeHolder0);

            vm.expectEmit(true, true, false, true);
            emit ProjectSupportUpdated(currentRound, projectId, mimeHolder0, deltaSupport);
        }

        vm.prank(mimeHolder0);
        pool.supportProjects(_projectSupports);

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            uint256 projectId = _projectSupports[i].projectId;
            string memory projectIdStr = Strings.toString(projectId);
            int256 deltaSupport = _projectSupports[i].deltaSupport;

            uint256 projectSupportBefore = projectTotalSupportsBefore[i];
            uint256 projectSupportAfter = pool.getProjectSupport(projectId);
            uint256 participantSupportBefore = projectParticipantSupportsBefore[i];
            uint256 participantSupportAfter = pool.getParticipantSupport(projectId, mimeHolder0);

            assertEq(
                projectSupportAfter,
                uint256(int256(projectSupportBefore) + deltaSupport),
                string.concat("Project ", projectIdStr, " total support mismatch")
            );
            assertEq(
                participantSupportAfter,
                uint256(int256(participantSupportBefore) + deltaSupport),
                string.concat("Project ", projectIdStr, " participant support mismatch")
            );
        }
    }

    function _assertOsmoticParam(int128 _poolParam, uint256 _param) private {
        assertEq(_poolParam.mulu(1e18), _param);
    }
}
