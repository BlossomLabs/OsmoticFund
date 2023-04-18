// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {BaseSetup} from "./BaseSetup.sol";

import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";

abstract contract ProjectRegistrySetup is BaseSetup {
    ProjectRegistry projectRegistry;
    address projectAdmin = makeAddr("projectAdmin");
    address projectBeneficiary = makeAddr("projectBeneficiary");

    function setUp() public virtual override {
        super.setUp();

        (, address projectRegistryAddress) = createProjectRegistry(VERSION);
        projectRegistry = ProjectRegistry(projectRegistryAddress);
    }
}
