// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ProjectRegistrySetup} from "../setups/ProjectRegistrySetup.sol";

import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";

contract ProjectRegistryInitialize is ProjectRegistrySetup {
    address projectRegistryImplementation;
    // TODO: find a way to get the counterfactual addres
    address expectedInitializedProjectRegistry = 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9;

    function setUp() public override {
        super.setUp();

        projectRegistryImplementation = setUpContract("ProjectRegistry", abi.encode(VERSION));
    }

    function test_Initialize() public {
        vm.expectCall(projectRegistryImplementation, abi.encodeCall(ProjectRegistry.initialize, ()));
        address initializedProjectRegistry =
            setUpProxy(projectRegistryImplementation, abi.encodeCall(ProjectRegistry.initialize, ()));

        assertEq(initializedProjectRegistry, expectedInitializedProjectRegistry);
    }
}
