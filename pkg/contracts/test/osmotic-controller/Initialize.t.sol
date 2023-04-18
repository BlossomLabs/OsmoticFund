// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {BaseSetup} from "../setups/BaseSetup.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";

contract Dummy {}

contract OsmoticControllerInitialize is BaseSetup {
    address controllerImplementation;
    address projectRegistry;
    address owner = makeAddr("owner");

    function setUp() public override {
        super.setUp();
        (, projectRegistry) = createProjectRegistry(VERSION);
        address dummy_ = address(new Dummy());

        controllerImplementation = setUpContract(
            "OsmoticController",
            abi.encode(
                VERSION, dummy_, projectRegistry, MIME_TOKEN_FACTORY_ADDRESS, ROUND_DURATION, CFA_V1_FORWARDER_ADDRESS
            )
        );
    }

    function test_Initialize() public {
        vm.startPrank(owner);
        address controller_ = setUpProxy(controllerImplementation, _encodeInitPayload(ROUND_DURATION));
        OsmoticController controller = OsmoticController(controller_);

        assertFalse(controller.paused(), "pausable not initialized");
        assertEq(controller.owner(), owner, "ownable not initialized");
        assertTrue(controller.isList(projectRegistry), "project registry not set as project list");
        assertEq(controller.claimDuration(), ROUND_DURATION, "round duration mismatch");
    }

    function _encodeInitPayload(uint256 _roundDuration) private pure returns (bytes memory) {
        return abi.encodeCall(OsmoticController.initialize, (_roundDuration));
    }
}
