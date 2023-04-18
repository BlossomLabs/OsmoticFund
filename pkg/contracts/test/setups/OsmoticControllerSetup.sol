// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {BaseSetup} from "./BaseSetup.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";

abstract contract OsmoticControllerSetup is BaseSetup {
    OsmoticController controller;
    address projectRegistryAddress;

    address owner = makeAddr("owner");
    address notOwner = makeAddr("notOwner");

    function setUp() public virtual override {
        super.setUp();

        (, projectRegistryAddress) = createProjectRegistry(VERSION);
        (, address controllerAddress) = createOsmoticControllerAndPoolImpl(
            VERSION, projectRegistryAddress, MIME_TOKEN_FACTORY_ADDRESS, ROUND_DURATION, CFA_V1_FORWARDER_ADDRESS
        );

        controller = OsmoticController(controllerAddress);
    }
}
