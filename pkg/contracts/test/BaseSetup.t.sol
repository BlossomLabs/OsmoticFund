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
        assertEq(controller.mimeTokenFactory(), address(mimeTokenFactory), "Controller: mime token factory mismatch");
        assertEq(controller.projectRegistry(), address(registry), "Controller: project registry mismatch");
        assertEq(controller.claimDuration(), roundDuration, "Controller: claim duration mismatch");
        assertEq(controller.implementation(), controllerImplementation, "Controller: implementation mismatch");
        assertEq(
            controller.osmoticPoolImplementation(),
            osmoticPoolImplementation,
            "Controller: pool implementation mismatch"
        );
        assertEq(controller.isList(address(registry)), true, "Controller: registry not set as default list");
        assertEq(controller.isToken(address(mimeToken)), true, "Controller: governance token not mime");
        assertEq(controller.isPool(address(pool)), true, "Controller: pool is not registered");

        // token
        assertEq(mimeToken.owner(), deployer, "Token: owner mismatch");
        assertEq(mimeToken.name(), "Osmotic Fund", "Token: name mismatch");
        assertEq(mimeToken.symbol(), "OF", "Token: symbol mismatch");
        assertEq(mimeToken.decimals(), 18, "Token: decimals mismatch");
        assertEq(mimeToken.merkleRoot(), merkleRoot, "Token: merkle root mismatch");
        assertEq(mimeToken.timestamp(), controller.claimTimestamp(), "Token: timestamp mismatch");
        assertEq(mimeToken.roundDuration(), controller.claimDuration(), "Token: round duration mismatch");

        // pool
        assertEq(pool.owner(), deployer, "Pool: owner mismatch");
        assertEq(pool.controller(), address(controller), "Pool: controller mismatch");
        assertEq(pool.cfaForwarder(), cfaV1ForwarderAddress, "Pool: cfa forwarder mismatch");
        assertEq(pool.fundingToken(), address(fundingToken), "Pool: funding token mismatch");
        assertEq(pool.mimeToken(), address(mimeToken), "Pool: governance token mismatch");
        assertEq(pool.projectList(), address(registry), "Pool: project list mismatch");
    }
}
