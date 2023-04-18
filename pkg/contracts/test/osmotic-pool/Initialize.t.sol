// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {BaseSetup} from "../setups/BaseSetup.sol";

import {InvalidProjectList, InvalidMimeToken, OsmoticPool, OsmoticParams} from "../../src/OsmoticPool.sol";
import {OsmoticFormula} from "../../src/OsmoticFormula.sol";

contract OsmoticPoolInitialize is BaseSetup {
    address poolImplementation;
    address invalidAddress = makeAddr("invalidAddress");

    address projectRegistry;
    address controller;
    address mimeToken;

    function setUp() public override {
        super.setUp();

        (, projectRegistry) = createProjectRegistry(VERSION);

        (, controller) = createOsmoticControllerAndPoolImpl(
            VERSION, projectRegistry, MIME_TOKEN_FACTORY_ADDRESS, ROUND_DURATION, CFA_V1_FORWARDER_ADDRESS
        );

        mimeToken = createMimeTokenFromController(controller, MERKLE_ROOT);

        poolImplementation = createOsmoticPoolImplementation(CFA_V1_FORWARDER_ADDRESS, controller);
    }

    function test_Initialize() public {
        bytes memory initPayload = _encodeInitPayload(FUNDING_TOKEN_ADDRESS, mimeToken, projectRegistry, OSMOTIC_PARAMS);

        (, address proxy) = createBeaconAndProxy(poolImplementation, initPayload);
        OsmoticPool initializedPool = OsmoticPool(proxy);

        assertEq(initializedPool.fundingToken(), FUNDING_TOKEN_ADDRESS, "Funding token mismatch");
        assertEq(initializedPool.mimeToken(), address(mimeToken), "Mime token mismatch");
        assertEq(initializedPool.projectList(), address(projectRegistry), "Project list mismatch");
        assertEq(initializedPool.owner(), address(this), "Owner mismatch");

        assertOsmoticParams(OsmoticFormula(initializedPool), OSMOTIC_PARAMS);
    }

    function test_RevertWhen_InitializingWithNoFundingToken() public {
        bytes memory initPayload = _encodeInitPayload(address(0), mimeToken, projectRegistry, OSMOTIC_PARAMS);

        expectRevertWhenCreatingBeaconProxy(poolImplementation, initPayload, "Zero Funding Token");
    }

    function test_RevertWhen_InitializingWithInvalidMimeToken() public {
        bytes memory initPayload =
            _encodeInitPayload(FUNDING_TOKEN_ADDRESS, invalidAddress, projectRegistry, OSMOTIC_PARAMS);

        expectRevertWhenCreatingBeaconProxy(
            poolImplementation, initPayload, abi.encodeWithSelector(InvalidMimeToken.selector)
        );
    }

    function test_RevertWhen_InitializingWithInvalidProjectList() public {
        bytes memory initPayload = _encodeInitPayload(FUNDING_TOKEN_ADDRESS, mimeToken, invalidAddress, OSMOTIC_PARAMS);

        expectRevertWhenCreatingBeaconProxy(
            poolImplementation, initPayload, abi.encodeWithSelector(InvalidProjectList.selector)
        );
    }

    function _encodeInitPayload(
        address _fundingToken,
        address _mimeToken,
        address _projectList,
        OsmoticParams memory _params
    ) private pure returns (bytes memory) {
        return abi.encodeWithSelector(OsmoticPool.initialize.selector, _fundingToken, _mimeToken, _projectList, _params);
    }
}
