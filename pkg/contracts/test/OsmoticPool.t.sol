// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";
import "@oz/utils/Strings.sol";
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

    uint256 poolTotalFunds = 100000 ether;
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

        vm.prank(address(fundingToken));
        fundingToken.selfMint(address(pool), poolTotalFunds, new bytes(0));

        projectId0 = createProject();
        projectId1 = createProject();
    }

    function test_FuzzSupportProjects(int32[] memory _supports) public {
        ProjectSupport[] memory projectSupports = _processFuzzedSupports(_supports, true);

        _supportProjectsAndAssert(projectSupports);
    }

    function test_FuzzSupportAndUnsupportProjects(int32[] memory _supports) public {
        ProjectSupport[] memory projectSupports = _processFuzzedSupports(_supports, false);

        // Add initial support for negative support changes.
        for (uint256 i = 0; i < projectSupports.length; i++) {
            int256 deltaSupport = projectSupports[i].deltaSupport;

            if (deltaSupport < 0) {
                int256 initialSupport = -(projectSupports[i].deltaSupport * 2);
                supportProject(mimeHolder0, projectSupports[i].projectId, initialSupport);
            }
        }

        _supportProjectsAndAssert(projectSupports);
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
        uint256 poolTotalSupportBefore = pool.getTotalSupport();

        vm.prank(mimeHolder0);
        pool.supportProjects(projectSupports);

        uint256 projectSupportAfter = pool.getProjectSupport(projectId0);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId0, mimeHolder0);
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

    function _supportProjectsAndAssert(ProjectSupport[] memory _projectSupports) private {
        uint256[] memory projectTotalSupportsBefore = new uint256[](_projectSupports.length);
        uint256[] memory projectParticipantSupportsBefore = new uint256[](_projectSupports.length);
        int256 totalSupportBefore = int256(pool.getTotalSupport());
        int256 totalDeltaSupport = 0;

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            uint256 projectId = _projectSupports[i].projectId;
            int256 deltaSupport = _projectSupports[i].deltaSupport;

            totalDeltaSupport += deltaSupport;

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

        uint256 totalSupportAfter = pool.getTotalSupport();

        assertEq(totalSupportAfter, uint256(totalSupportBefore + totalDeltaSupport), "Pool total support mismatch");
    }

    function _assertOsmoticParam(int128 _poolParam, uint256 _param) private {
        assertEq(_poolParam.mulu(1e18), _param);
    }

    function _mockMimeHolderBalance(address _holder, uint256 _amount) private {
        vm.mockCall(
            address(mimeToken),
            abi.encodeWithSelector(MimeToken.balanceOf.selector, address(_holder)),
            abi.encode(_amount)
        );
    }

    function _processFuzzedSupports(int32[] memory _fuzzedSupports, bool _onlyPositiveSupports)
        private
        returns (ProjectSupport[] memory projectSupports)
    {
        vm.assume(_fuzzedSupports.length > 0);
        uint256 supportsLength = bound(_fuzzedSupports.length, 1, pool.MAX_ACTIVE_PROJECTS());

        _mockMimeHolderBalance(mimeHolder0, type(uint256).max);

        projectSupports = new ProjectSupport[](supportsLength);

        for (uint256 i = 0; i < supportsLength; i++) {
            int256 delta;

            if (_onlyPositiveSupports) {
                delta = int256(uint256(uint32(_fuzzedSupports[i])));
            } else {
                delta = int256(_fuzzedSupports[i]);
            }

            projectSupports[i].projectId = createProject();
            projectSupports[i].deltaSupport = delta * 1e18;
        }
    }
}
