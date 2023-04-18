// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/StdMath.sol";

import "@oz/utils/Strings.sol";
import {MimeToken} from "mime-token/MimeToken.sol";

import {OsmoticPoolSetup} from "../setups/OsmoticPoolSetup.sol";

import {ProjectSupport, SupportUnderflow} from "../../src/OsmoticPool.sol";
import {ProjectNotInList} from "../../src/interfaces/IProjectList.sol";

contract OsmoticPoolSupportProjects is OsmoticPoolSetup {
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);

    function testFuzz_SupportProjects(int32[MAX_ACTIVE_PROJECTS] memory _supports) public {
        bool onlyPositiveSupports = true;
        bool onlyNonZeroSupports = false;
        ProjectSupport[] memory projectSupports = _normalizeFuzzedSupports(
            MIME_HOLDER0, _supports, MAX_ACTIVE_PROJECTS, onlyPositiveSupports, onlyNonZeroSupports
        );

        _supportProjectsAndAssert(MIME_HOLDER0, projectSupports);
    }

    function testFuzz_SupportAndUnsupportProjects(int32[MAX_ACTIVE_PROJECTS] memory _supports) public {
        bool onlyPositiveSupports = false;
        bool onlyNonZeroSupports = false;
        ProjectSupport[] memory projectSupports = _normalizeFuzzedSupports(
            MIME_HOLDER0, _supports, MAX_ACTIVE_PROJECTS, onlyPositiveSupports, onlyNonZeroSupports
        );

        // Apply an initial support to projects with negative support changes so we don't overflow.
        for (uint256 i = 0; i < projectSupports.length; i++) {
            int256 deltaSupport = projectSupports[i].deltaSupport;

            if (deltaSupport < 0) {
                int256 initialSupport = int256(stdMath.abs(projectSupports[i].deltaSupport * 2));
                _supportProject(MIME_HOLDER0, projectSupports[i].projectId, initialSupport);
            }
        }

        _supportProjectsAndAssert(MIME_HOLDER0, projectSupports);
    }

    function test_SupportAndUnsupportProjectAtTheSameTime() public {
        uint256 projectId = _createProject();
        string memory projectIdStr = Strings.toString(projectId);
        ProjectSupport[] memory projectSupports = new ProjectSupport[](2);

        projectSupports[0].projectId = projectId;
        projectSupports[1].projectId = projectId;

        projectSupports[0].deltaSupport = 20 ether;
        projectSupports[1].deltaSupport = -10 ether;

        int256 newDeltaSupport = projectSupports[0].deltaSupport + projectSupports[1].deltaSupport;

        uint256 projectSupportBefore = pool.getProjectSupport(projectId);
        uint256 participantSupportBefore = pool.getParticipantSupport(projectId, MIME_HOLDER0);
        uint256 poolTotalSupportBefore = pool.getTotalSupport();

        vm.prank(MIME_HOLDER0);
        pool.supportProjects(projectSupports);

        uint256 projectSupportAfter = pool.getProjectSupport(projectId);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId, MIME_HOLDER0);
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

    function test_RevertWhen_SupportingProjectsWithoutBalance() public {
        uint256 projectId = _createProject();
        address invalidParticipant = makeAddr("invalidParticipant");

        vm.expectRevert("NO_BALANCE_AVAILABLE");
        _supportProject(invalidParticipant, projectId, 20 ether);
    }

    function test_RevertWhen_SupportingInvalidProjects() public {
        uint256 invalidProjectId = 999;

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, invalidProjectId));
        _supportProject(MIME_HOLDER0, invalidProjectId, 20 ether);
    }

    function test_RevertWhen_SupportingWithMoreThanAvailableBalance() public {
        uint256 projectId = _createProject();
        uint256 holderBalance = mimeToken.balanceOf(MIME_HOLDER0);

        vm.expectRevert("NOT_ENOUGH_BALANCE");
        _supportProject(MIME_HOLDER0, projectId, int256(holderBalance + 1 ether));
    }

    function test_RevertWhen_SupportingProjectsWithSupportUnderflow() public {
        uint256 projectId = _createProject();
        int256 deltaSupport = 20 ether;
        _supportProject(MIME_HOLDER0, projectId, deltaSupport);

        vm.expectRevert(abi.encodeWithSelector(SupportUnderflow.selector));
        _supportProject(MIME_HOLDER0, projectId, -deltaSupport - 1 ether);
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

            vm.expectEmit(true, true, true, true);
            emit ProjectSupportUpdated(
                CURRENT_ROUND, _projectSupports[i].projectId, mimeHolder, _projectSupports[i].deltaSupport
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
}
