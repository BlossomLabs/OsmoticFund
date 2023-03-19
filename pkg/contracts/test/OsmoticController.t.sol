// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {MimeToken} from "mime-token/MimeTokenFactory.sol";

import {InvalidProjectList, OsmoticPool, OsmoticParams} from "../src/OsmoticPool.sol";

import {IProjectList} from "../src/interfaces/IProjectList.sol";

import {BaseSetup} from "../script/BaseSetup.s.sol";

contract OsmoticControllerTest is Test, BaseSetup {
    OsmoticPool pool;
    OsmoticParams params;

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    function setUp() public override {
        super.setUp();

        params = OsmoticParams({decay: 1, drop: 2, maxFlow: 3, minStakeRatio: 4});

        bytes memory initCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(governanceToken), address(registry), params)
        );

        pool = OsmoticPool(controller.createOsmoticPool(initCall));
    }

    function testPause() public {
        controller.pause();
        assertTrue(controller.paused(), "paused mismatch");
    }

    function testUnpause() public {
        controller.pause();
        controller.unpause();
        assertTrue(!controller.paused(), "paused mismatch");
    }

    function testUpdateOsmoticPoolImplementation() public {
        address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));
        UpgradeableBeacon beacon = UpgradeableBeacon(controller.beacon());
        beacon.upgradeTo(newImplementation);

        assertEq(controller.osmoticPoolImplementation(), newImplementation, "poolImplementation mismatch");
    }

    function testCreateOsmoticPool() public {
        assertEq(controller.isPool(address(pool)), true, "pool is not registered");
    }

    function testCreatePoolWithListNotRegistered() public {
        IProjectList projectList = IProjectList(address(20));

        bytes memory initCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(governanceToken), address(projectList), params)
        );

        vm.expectRevert(abi.encodeWithSelector(InvalidProjectList.selector));

        controller.createOsmoticPool(initCall);
    }

    function testCreateOwnedList() public {
        address newList = controller.createProjectList("New list");

        assertEq(controller.isList(newList), true, "new list is not registered");
    }

    function testCreatePoolWithOwnedList() public {
        IProjectList newList = IProjectList(controller.createProjectList("New list"));

        bytes memory initCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(governanceToken), address(newList), params)
        );

        address newPool = controller.createOsmoticPool(initCall);

        assertEq(controller.isPool(newPool), true, "pool is not registered");
    }

    function testCreateMimeToken() public {
        bytes memory initCall = abi.encodeCall(
            MimeToken.initialize,
            (
                "Mime Token",
                "MIME",
                0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d,
                block.timestamp,
                1
            )
        );
        MimeToken newToken = MimeToken(controller.createMimeToken(initCall));

        assertEq(controller.isToken(address(newToken)), true, "token is not registered");
        assertEq(newToken.owner(), deployer, "token owner mismatch");
    }

    function testCreatePool() public {
        bytes memory governanceTokenInitCall = abi.encodeCall(
            MimeToken.initialize,
            (
                "Mime Token",
                "MIME",
                0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d,
                block.timestamp,
                1
            )
        );

        IProjectList newList = IProjectList(controller.createProjectList("New list"));

        (address newToken, address newPool) =
            controller.createPool(address(fundingToken), address(newList), governanceTokenInitCall, params);

        assertEq(controller.isPool(newPool), true, "pool is not registered");
        assertEq(controller.isToken(newToken), true, "token is not registered");
        assertEq(MimeToken(newToken).owner(), deployer, "token owner mismatch");
    }
}
