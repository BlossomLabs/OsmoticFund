// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "forge-std/console.sol";
import "forge-std/Test.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import "@oz/utils/Strings.sol";
import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";
import {MimeToken} from "mime-token/MimeToken.sol";

import {
    OsmoticPool,
    ProjectSupport,
    PoolProject,
    ProjectAlreadyActive,
    ProjectNeedsMoreStake,
    ProjectWithoutSupport,
    SupportUnderflow
} from "../src/OsmoticPool.sol";
import {OsmoticFormula, OsmoticParams} from "../src/OsmoticFormula.sol";
import {Project, ProjectNotInList} from "../src/interfaces/IProjectList.sol";
import {BaseSetUpWithProjectList} from "../script/BaseSetUpWithProjectList.s.sol";

contract OsmoticPoolTest is Test, BaseSetUpWithProjectList {
    using ABDKMath64x64 for int128;

    uint256 poolTotalFunds = 100_000 ether;

    OsmoticParams newOsmoticParams = OsmoticParams({decay: 1000, drop: 1001, maxFlow: 1002, minStakeRatio: 1003});

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);
    event OsmoticParamsChanged(uint256 decay, uint256 drop, uint256 maxFlow, uint256 minStakeRatio);

    uint256 constant MAX_ACTIVE_PROJECTS = 25;

    function setUp() public override {
        super.setUp();

        vm.prank(address(fundingToken));
        fundingToken.selfMint(address(pool), poolTotalFunds, new bytes(0));
    }

    function test_FuzzSupportProjects(int32[MAX_ACTIVE_PROJECTS] memory _supports) public {
        ProjectSupport[] memory projectSupports =
            _processFuzzedSupports(mimeHolder0, _supports, MAX_ACTIVE_PROJECTS, true, false);

        _supportProjectsAndAssert(mimeHolder0, projectSupports);
    }

    function test_FuzzSupportAndUnsupportProjects(int32[MAX_ACTIVE_PROJECTS] memory _supports) public {
        ProjectSupport[] memory projectSupports =
            _processFuzzedSupports(mimeHolder0, _supports, MAX_ACTIVE_PROJECTS, false, false);

        // Apply an initial support to projects with negative support changes.
        for (uint256 i = 0; i < projectSupports.length; i++) {
            int256 deltaSupport = projectSupports[i].deltaSupport;

            if (deltaSupport < 0) {
                int256 initialSupport = int256(stdMath.abs(projectSupports[i].deltaSupport * 2));
                supportProject(mimeHolder0, projectSupports[i].projectId, initialSupport);
            }
        }

        _supportProjectsAndAssert(mimeHolder0, projectSupports);
    }

    function test_SupportAndUnsupportProjectAtTheSameTime() public {
        uint256 projectId = createProject();
        string memory projectIdStr = Strings.toString(projectId);
        ProjectSupport[] memory projectSupports = new ProjectSupport[](2);

        projectSupports[0].projectId = projectId;
        projectSupports[1].projectId = projectId;

        projectSupports[0].deltaSupport = 20 ether;
        projectSupports[1].deltaSupport = -10 ether;

        int256 newDeltaSupport = projectSupports[0].deltaSupport + projectSupports[1].deltaSupport;

        uint256 projectSupportBefore = pool.getProjectSupport(projectId);
        uint256 participantSupportBefore = pool.getParticipantSupport(projectId, mimeHolder0);
        uint256 poolTotalSupportBefore = pool.getTotalSupport();

        vm.prank(mimeHolder0);
        pool.supportProjects(projectSupports);

        uint256 projectSupportAfter = pool.getProjectSupport(projectId);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId, mimeHolder0);
        uint256 poolTotalSupportAfter = pool.getTotalSupport();

        uint256 expectedProjectSupport = uint256(int256(projectSupportBefore) + newDeltaSupport);
        uint256 expectedParticipantSupport = uint256(int256(participantSupportBefore) + newDeltaSupport);
        uint256 expectedPoolTotalSupport = uint256(int256(poolTotalSupportBefore) + newDeltaSupport);

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
        assertEq(poolTotalSupportAfter, expectedPoolTotalSupport, "Pool total support mismatch");
    }

    function test_RevertWhenSupportingProjectsWithoutBalance() public {
        uint256 projectId = createProject();
        address invalidParticipant = address(999);

        vm.expectRevert("NO_BALANCE_AVAILABLE");
        supportProject(invalidParticipant, projectId, 20 ether);
    }

    function test_RevertWhenSupportingInvalidProjects() public {
        uint256 invalidProjectId = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, invalidProjectId));
        supportProject(mimeHolder0, invalidProjectId, 20 ether);
    }

    function test_RevertWhenSupportingWithMoreThanAvailableBalance() public {
        uint256 projectId = createProject();
        uint256 holderBalance = mimeToken.balanceOf(mimeHolder0);

        vm.expectRevert("NOT_ENOUGH_BALANCE");
        supportProject(mimeHolder0, projectId, int256(holderBalance + 1 ether));
    }

    function test_RevertWhenSupportingProjectsWithSupportUnderflow() public {
        uint256 projectId = createProject();
        int256 deltaSupport = 20 ether;
        supportProject(mimeHolder0, projectId, deltaSupport);

        vm.expectRevert(abi.encodeWithSelector(SupportUnderflow.selector));
        supportProject(mimeHolder0, projectId, -deltaSupport - 1 ether);
    }

    function test_ActivateProject() public {
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

        (uint256 flowLastRate,, bool active,) = pool.poolProjects(deactivatedProjectId);
        assertFalse(active);
        assertEq(flowLastRate, 0);
    }

    function test_RevertWhenActivatingProjectNotInList() public {
        uint256 nonExistentProject = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, nonExistentProject));
        pool.activateProject(nonExistentProject);
    }

    function test_RevertWhenActivatingProjectwithoutSupport() public {
        uint256 projectId = createProject();
        vm.expectRevert(abi.encodeWithSelector(ProjectWithoutSupport.selector, projectId));
        pool.activateProject(projectId);
    }

    function test_RevertWhenActivatingAlreadyActivedProject() public {
        uint256 projectId = createProject();
        supportProject(mimeHolder0, projectId, 10);
        pool.activateProject(projectId);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyActive.selector, projectId));
        pool.activateProject(projectId);
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

    function test_ClaimAndSupportProjects() public {
        uint256 projectId = createProject();
        ProjectSupport[] memory projectSupports = new ProjectSupport[](1);
        uint256 claimedAmount = unclaimedAmount;
        projectSupports[0].projectId = projectId;
        projectSupports[0].deltaSupport = int256(unclaimedAmount);

        uint256 holderBalanceBefore = mimeToken.balanceOf(unclaimedMimeHolder3);
        uint256 projectSupportBefore = pool.getProjectSupport(projectId);
        uint256 participantSupportBefore = pool.getParticipantSupport(projectId, unclaimedMimeHolder3);

        vm.expectCall(
            address(mimeToken),
            abi.encodeWithSelector(MimeToken.claim.selector, 3, unclaimedMimeHolder3, claimedAmount, holdersProofs[3])
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectSupportUpdated(currentRound, projectId, unclaimedMimeHolder3, projectSupports[0].deltaSupport);

        vm.prank(unclaimedMimeHolder3);
        pool.claimAndSupportProjects(3, unclaimedMimeHolder3, claimedAmount, holdersProofs[3], projectSupports);

        uint256 holderBalanceAfter = mimeToken.balanceOf(unclaimedMimeHolder3);
        uint256 projectSupportAfter = pool.getProjectSupport(projectId);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId, unclaimedMimeHolder3);

        assertEq(holderBalanceAfter, holderBalanceBefore + unclaimedAmount, "Mime holder balance mismatch");
        assertEq(projectSupportAfter, projectSupportBefore + claimedAmount, "Project support mismatch");
        assertEq(
            participantSupportAfter, participantSupportBefore + claimedAmount, "Project participant support mismatch"
        );
    }

    function test_FuzzSync(int32[MAX_ACTIVE_PROJECTS] memory _supports, uint256 _timePassed) public {
        // Reduce project supports to decrease test duration
        ProjectSupport[] memory projectSupports =
            _processFuzzedSupports(mimeHolder0, _supports, MAX_ACTIVE_PROJECTS / 2, true, true);
        _timePassed = bound(_timePassed, 1, roundDuration - 1);

        uint256 initialTimestamp = block.timestamp;

        // Set up pool projects
        vm.prank(mimeHolder0);
        pool.supportProjects(projectSupports);
        activateAllProjects();

        skip(_timePassed);

        uint256[] memory expectedFlowsLastTimes = new uint256[](projectSupports.length);
        uint256[] memory expectedFlowsLastRate = new uint256[](projectSupports.length);
        uint256 poolFunds = fundingToken.balanceOf(address(pool));
        uint256 totalSupport = 0;

        for (uint256 i = 0; i < projectSupports.length; i++) {
            totalSupport += uint256(projectSupports[i].deltaSupport);
            expectedFlowsLastTimes[i] = block.timestamp;
        }

        for (uint256 i = 0; i < projectSupports.length; i++) {
            // (uint256 flowLastRate, uint256 flowLastTime,,) = pool.poolProjects(projectSupports[i].projectId);
            expectedFlowsLastRate[i] = _calculateFlowRate(
                OsmoticFormula(pool),
                poolFunds,
                totalSupport,
                0,
                initialTimestamp,
                uint256(projectSupports[i].deltaSupport)
            );

            vm.expectEmit(true, true, true, true);
            emit FlowSynced(
                projectSupports[i].projectId,
                registry.getProject(projectSupports[i].projectId).beneficiary,
                expectedFlowsLastRate[i]
            );
        }

        pool.sync();

        uint256[] memory flowsLastRate = new uint256[](projectSupports.length);
        uint256[] memory flowsLastTime = new uint256[](projectSupports.length);

        for (uint256 i = 0; i < projectSupports.length; i++) {
            (uint256 flowLastRate, uint256 flowLastTime,,) = pool.poolProjects(projectSupports[i].projectId);
            flowsLastRate[i] = flowLastRate;
            flowsLastTime[i] = flowLastTime;
        }

        assertEq(flowsLastRate, expectedFlowsLastRate, "Flows last rate mismatch");
        assertEq(flowsLastTime, expectedFlowsLastTimes, "Flows last time mismatch");
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

    function _supportProjectsAndAssert(address mimeHolder, ProjectSupport[] memory _projectSupports) private {
        uint256[] memory projectTotalSupportsBefore = new uint256[](_projectSupports.length);
        uint256[] memory projectParticipantSupportsBefore = new uint256[](_projectSupports.length);
        int256 totalSupportBefore = int256(pool.getTotalSupport());
        int256 totalDeltaSupport = 0;

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            totalDeltaSupport += _projectSupports[i].deltaSupport;

            projectTotalSupportsBefore[i] = pool.getProjectSupport(_projectSupports[i].projectId);
            projectParticipantSupportsBefore[i] = pool.getParticipantSupport(_projectSupports[i].projectId, mimeHolder);

            vm.expectEmit(true, true, false, true);
            emit ProjectSupportUpdated(
                currentRound, _projectSupports[i].projectId, mimeHolder, _projectSupports[i].deltaSupport
            );
        }

        vm.prank(mimeHolder);
        pool.supportProjects(_projectSupports);

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            string memory projectIdStr = Strings.toString(_projectSupports[i].projectId);

            uint256 projectSupportBefore = projectTotalSupportsBefore[i];
            uint256 projectSupportAfter = pool.getProjectSupport(_projectSupports[i].projectId);
            uint256 participantSupportBefore = projectParticipantSupportsBefore[i];
            uint256 participantSupportAfter = pool.getParticipantSupport(_projectSupports[i].projectId, mimeHolder);

            assertEq(
                projectSupportAfter,
                uint256(int256(projectSupportBefore) + _projectSupports[i].deltaSupport),
                string.concat("Project ", projectIdStr, " total support mismatch")
            );
            assertEq(
                participantSupportAfter,
                uint256(int256(participantSupportBefore) + _projectSupports[i].deltaSupport),
                string.concat("Project ", projectIdStr, " participant support mismatch")
            );
        }

        uint256 totalSupportAfter = pool.getTotalSupport();

        assertEq(totalSupportAfter, uint256(totalSupportBefore + totalDeltaSupport), "Pool total support mismatch");
    }

    function _assertOsmoticParam(int128 _poolParam, uint256 _param) private {
        assertEq(_poolParam.mulu(1e18), _param);
    }

    function _processFuzzedSupports(
        address mimeHolder,
        int32[MAX_ACTIVE_PROJECTS] memory _fuzzedSupports,
        uint256 _supportsLength,
        bool _onlyPositiveSupports,
        bool _onlyNonZeroSupports
    ) private returns (ProjectSupport[] memory projectSupports) {
        vm.assume(_fuzzedSupports.length > 0);
        uint256 supportsLength = bound(_fuzzedSupports.length, 1, _supportsLength);

        // Set maximum balance possible for holder
        vm.mockCall(
            address(mimeToken),
            abi.encodeWithSelector(MimeToken.balanceOf.selector, address(mimeHolder)),
            abi.encode(type(uint256).max)
        );

        projectSupports = new ProjectSupport[](supportsLength);

        for (uint256 i = 0; i < supportsLength; i++) {
            int256 delta;

            if (_onlyPositiveSupports) {
                delta = int256(uint256(uint32(_fuzzedSupports[i])));
            } else {
                delta = int256(_fuzzedSupports[i]);
            }

            if (_onlyNonZeroSupports && delta == 0) {
                delta = 1;
            }

            projectSupports[i].projectId = createProject();
            projectSupports[i].deltaSupport = delta * 1e18;
        }
    }

    function _calculateFlowRate(
        OsmoticFormula _formula,
        uint256 _poolFunds,
        uint256 _poolTotalSupport,
        uint256 _flowLastRate,
        uint256 _flowLastTime,
        uint256 _projectSupport
    ) private returns (uint256) {
        uint256 targetRate = _formula.calculateTargetRate(_poolFunds, _projectSupport, _poolTotalSupport);
        uint256 timePassed = block.timestamp - _flowLastTime;

        return _formula.calculateRate(timePassed, _flowLastRate, targetRate);
    }
}
