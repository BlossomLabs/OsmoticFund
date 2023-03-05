// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {BaseSetup} from "../script/BaseSetup.s.sol";

contract BaseSetupTest is Test, BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testInitialize() public {
        // registry
        assertEq(registry.version(), 1, "Registry: version mismatch");
        assertEq(registry.owner(), deployer, "Registry: owner mismatch");
        assertEq(registry.nextProjectId(), 1, "Registry: nextProjectId mismatch");
        assertEq(registry.implementation(), registryImplementation, "Registry: implementation mismatch");

        // controller
        assertEq(controller.version(), 1, "Controller: version mismatch");
        assertEq(controller.owner(), deployer, "Controller: owner mismatch");
        assertEq(controller.implementation(), controllerImplementation, "Controller: implementation mismatch");
        assertEq(
            controller.osmoticPoolImplementation(),
            osmoticPoolImplementation,
            "Controller: pool implementation mismatch"
        );
        assertEq(controller.projectRegistry(), address(registry), "Controller: project registry mismatch");
        assertEq(controller.isList(address(registry)), true, "Controller: registry not set as default list");
        assertEq(controller.isToken(address(governanceToken)), true, "Controller: governance token not mime");

        // token
        assertEq(governanceToken.name(), "Osmotic Fund", "Token: name mismatch");
        assertEq(governanceToken.symbol(), "OF", "Token: symbol mismatch");
        assertEq(governanceToken.merkleRoot(), merkleRoot, "Token: merkle root mismatch");
    }
}
