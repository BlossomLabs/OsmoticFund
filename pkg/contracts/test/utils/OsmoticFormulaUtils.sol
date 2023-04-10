// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";
import {ABDKMath64x64} from "abdk-libraries/ABDKMath64x64.sol";

import {OsmoticFormula, OsmoticParams} from "../../src/OsmoticFormula.sol";

abstract contract OsmoticFormulaUtils is Test {
    using ABDKMath64x64 for int128;

    function assertOsmoticParams(OsmoticFormula formula, OsmoticParams memory _osmoticParams) public {
        assertOsmoticParam(formula.decay(), _osmoticParams.decay, "Osmotic param decay mismatch");
        assertOsmoticParam(formula.drop(), _osmoticParams.drop, "Osmotic param drop mismatch");
        assertOsmoticParam(formula.maxFlow(), _osmoticParams.maxFlow, "Osmotic param maxFlow mismatch");
        assertOsmoticParam(
            formula.minStakeRatio(), _osmoticParams.minStakeRatio, "Osmotic param minStakeRatio mismatch"
        );
    }

    function assertOsmoticParam(int128 _poolParam, uint256 _param) public {
        assertEq(_poolParam.mulu(1e18), _param);
    }

    function assertOsmoticParam(int128 _poolParam, uint256 _param, string memory errorMessage) public {
        assertEq(_poolParam.mulu(1e18), _param, errorMessage);
    }

    function _calculateFlowRate(
        OsmoticFormula _formula,
        uint256 _poolFunds,
        uint256 _poolTotalSupport,
        uint256 _flowLastRate,
        uint256 _flowLastTime,
        uint256 _projectSupport
    ) internal view returns (uint256) {
        uint256 targetRate = _formula.calculateTargetRate(_poolFunds, _projectSupport, _poolTotalSupport);
        uint256 timePassed = block.timestamp - _flowLastTime;

        return _formula.calculateRate(timePassed, _flowLastRate, targetRate);
    }
}
