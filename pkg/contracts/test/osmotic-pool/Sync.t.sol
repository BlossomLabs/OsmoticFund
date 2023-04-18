// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticPoolSetup} from "../setups/OsmoticPoolSetup.sol";

import {OsmoticFormula} from "../../src/OsmoticFormula.sol";
import {ProjectSupport} from "../../src/OsmoticPool.sol";

contract OsmoticPoolSync is OsmoticPoolSetup {
    uint256 constant POOL_INITIAL_FUNDS = 100_000 ether;

    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);

    function setUp() public override {
        super.setUp();

        vm.prank(address(FUNDING_TOKEN));
        FUNDING_TOKEN.selfMint(address(pool), POOL_INITIAL_FUNDS, new bytes(0));
    }

    function testFuzz_Sync(int32[MAX_ACTIVE_PROJECTS] memory _supports, uint256 _timePassed) public {
        bool onlyPositiveSupports = true;
        bool onlyNonZeroSupports = true;
        // Reduce project supports to decrease test duration
        ProjectSupport[] memory projectSupports = _normalizeFuzzedSupports(
            MIME_HOLDER0, _supports, MAX_ACTIVE_PROJECTS / 2, onlyPositiveSupports, onlyNonZeroSupports
        );
        _timePassed = bound(_timePassed, 1, ROUND_DURATION - 1);

        // Set up pool projects
        vm.prank(MIME_HOLDER0);
        pool.supportProjects(projectSupports);
        _activateAllProjects();

        skip(_timePassed);

        uint256 expectedPoolFunds = FUNDING_TOKEN.balanceOf(address(pool));

        _assertSync(projectSupports, expectedPoolFunds);
    }

    function testFuzz_SyncWithApprovedFunds(
        int32[MAX_ACTIVE_PROJECTS] memory _supports,
        uint256 _timePassed,
        uint32 _allowance
    ) public {
        vm.assume(_allowance > 0);
        uint256 tokenAllowance = uint256(_allowance) * 1e18;
        bool onlyPositiveSupports = true;
        bool onlyNonZeroSupports = true;
        // Reduce project supports to decrease test duration
        ProjectSupport[] memory projectSupports = _normalizeFuzzedSupports(
            MIME_HOLDER0, _supports, MAX_ACTIVE_PROJECTS / 2, onlyPositiveSupports, onlyNonZeroSupports
        );
        _timePassed = bound(_timePassed, 1, ROUND_DURATION - 1);

        // Set up pool projects
        vm.prank(MIME_HOLDER0);
        pool.supportProjects(projectSupports);
        _activateAllProjects();

        vm.prank(address(FUNDING_TOKEN));
        FUNDING_TOKEN.selfMint(poolOwner, tokenAllowance, new bytes(0));

        vm.prank(poolOwner);
        FUNDING_TOKEN.approve(address(pool), tokenAllowance);

        skip(_timePassed);

        uint256 expectedPoolFunds =
            FUNDING_TOKEN.balanceOf(address(pool)) + FUNDING_TOKEN.allowance(poolOwner, address(pool));

        _assertSync(projectSupports, expectedPoolFunds);
    }

    function _assertSync(ProjectSupport[] memory _projectSupports, uint256 _expectedPoolFunds) private {
        uint256[] memory expectedFlowsLastTimes = new uint256[](_projectSupports.length);
        uint256[] memory expectedFlowsLastRate = new uint256[](_projectSupports.length);
        uint256 totalSupport = 0;

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            totalSupport += uint256(_projectSupports[i].deltaSupport);
            expectedFlowsLastTimes[i] = block.timestamp;
        }

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            (uint256 flowLastRate, uint256 flowLastTime,,) = pool.poolProjects(_projectSupports[i].projectId);

            expectedFlowsLastRate[i] = _calculateFlowRate(
                OsmoticFormula(pool),
                _expectedPoolFunds,
                totalSupport,
                flowLastRate,
                flowLastTime,
                uint256(_projectSupports[i].deltaSupport)
            );

            vm.expectEmit(true, true, true, true);
            emit FlowSynced(
                _projectSupports[i].projectId,
                projectList.getProject(_projectSupports[i].projectId).beneficiary,
                expectedFlowsLastRate[i]
            );
        }

        pool.sync();

        uint256[] memory flowsLastRate = new uint256[](_projectSupports.length);
        uint256[] memory flowsLastTime = new uint256[](_projectSupports.length);

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            (uint256 flowLastRate, uint256 flowLastTime,,) = pool.poolProjects(_projectSupports[i].projectId);
            flowsLastRate[i] = flowLastRate;
            flowsLastTime[i] = flowLastTime;
        }

        assertEq(flowsLastRate, expectedFlowsLastRate, "Flows last rate mismatch");
        assertEq(flowsLastTime, expectedFlowsLastTimes, "Flows last time mismatch");
    }
}
