// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticPoolSetup} from "../setups/OsmoticPoolSetup.sol";

import {OsmoticFormula, OsmoticParams} from "../../src/OsmoticFormula.sol";

contract OsmoticPoolSetOsmoticFormula is OsmoticPoolSetup {
    OsmoticParams NEW_OSMOTIC_PARAMS = OsmoticParams({decay: 1000, drop: 1001, maxFlow: 1002, minStakeRatio: 1003});

    event OsmoticParamsChanged(uint256 decay, uint256 drop, uint256 maxFlow, uint256 minStakeRatio);

    function test_SetOsmoticFormulaParams() public {
        vm.expectEmit(true, true, true, true);
        emit OsmoticParamsChanged(
            NEW_OSMOTIC_PARAMS.decay,
            NEW_OSMOTIC_PARAMS.drop,
            NEW_OSMOTIC_PARAMS.maxFlow,
            NEW_OSMOTIC_PARAMS.minStakeRatio
        );

        pool.setOsmoticFormulaParams(NEW_OSMOTIC_PARAMS);

        assertOsmoticParams(OsmoticFormula(pool), NEW_OSMOTIC_PARAMS);
    }

    function test_setOsmoticFormulaDecay() public {
        vm.expectEmit(true, true, true, true);
        emit OsmoticParamsChanged(
            NEW_OSMOTIC_PARAMS.decay, OSMOTIC_PARAMS.drop, OSMOTIC_PARAMS.maxFlow, OSMOTIC_PARAMS.minStakeRatio
        );

        pool.setOsmoticFormulaDecay(NEW_OSMOTIC_PARAMS.decay);

        assertOsmoticParam(pool.decay(), NEW_OSMOTIC_PARAMS.decay);
    }

    function test_setOsmoticFormulaDrop() public {
        vm.expectEmit(true, true, true, true);
        emit OsmoticParamsChanged(
            OSMOTIC_PARAMS.decay, NEW_OSMOTIC_PARAMS.drop, OSMOTIC_PARAMS.maxFlow, OSMOTIC_PARAMS.minStakeRatio
        );

        pool.setOsmoticFormulaDrop(NEW_OSMOTIC_PARAMS.drop);

        assertOsmoticParam(pool.drop(), NEW_OSMOTIC_PARAMS.drop);
    }

    function test_setOsmoticFormulaMaxFlow() public {
        vm.expectEmit(true, true, true, true);
        emit OsmoticParamsChanged(
            OSMOTIC_PARAMS.decay, OSMOTIC_PARAMS.drop, NEW_OSMOTIC_PARAMS.maxFlow, OSMOTIC_PARAMS.minStakeRatio
        );

        pool.setOsmoticFormulaMaxFlow(NEW_OSMOTIC_PARAMS.maxFlow);

        assertOsmoticParam(pool.maxFlow(), NEW_OSMOTIC_PARAMS.maxFlow);
    }

    function test_setOsmoticFormulaMinStakeRatio() public {
        vm.expectEmit(true, true, true, true);
        emit OsmoticParamsChanged(
            OSMOTIC_PARAMS.decay, OSMOTIC_PARAMS.drop, OSMOTIC_PARAMS.maxFlow, NEW_OSMOTIC_PARAMS.minStakeRatio
        );

        pool.setOsmoticFormulaMinStakeRatio(NEW_OSMOTIC_PARAMS.minStakeRatio);

        assertOsmoticParam(pool.minStakeRatio(), NEW_OSMOTIC_PARAMS.minStakeRatio);
    }
}
