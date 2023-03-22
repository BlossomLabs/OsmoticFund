// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {MimeToken} from "mime-token/MimeTokenFactory.sol";

import {InvalidProjectList, InvalidMimeToken, OsmoticPool, OsmoticParams} from "../src/OsmoticPool.sol";
import {OwnableProjectList} from "../src/projects/OwnableProjectList.sol";

import {BaseSetup} from "../script/BaseSetup.s.sol";

contract OsmoticControllerTest is Test, BaseSetup {
    address owner = address(1);

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    function setUp() public override {
        super.setUp();
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

    function testCallWhenPaused() public {
        controller.pause();

        vm.expectRevert("Pausable: paused");

        controller.createProjectList("New list");
    }

    function testUpdateOsmoticPoolImplementation() public {
        address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));
        UpgradeableBeacon(controller.beacon()).upgradeTo(newImplementation);

        assertEq(controller.osmoticPoolImplementation(), newImplementation, "poolImplementation mismatch");
    }

    function testUpdateOsmoticPoolImplementationWithNotOwner() public {
        address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(notAuthorized);
        UpgradeableBeacon(controller.beacon()).upgradeTo(newImplementation);
    }

    function testSetClaimDuration() public {
        assertEq(controller.claimDuration(), roundDuration, "claimDuration mismatch");

        uint256 newDuration = 2 weeks;
        controller.setClaimDuration(newDuration);
        assertEq(controller.claimDuration(), newDuration, "claimDuration mismatch");
    }

    function testSetClaimDurationWithNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(notAuthorized);
        controller.setClaimDuration(2 weeks);
    }

    function testCreateOwnedList() public {
        address newList = controller.createProjectList("New list");

        assertEq(controller.isList(newList), true, "new list is not registered");
    }

    function testCreateOsmoticPool() public {
        bytes memory poolInitCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(mimeToken), address(registry), params)
        );

        vm.prank(owner);
        OsmoticPool newPool = OsmoticPool(controller.createOsmoticPool(poolInitCall));

        assertEq(newPool.owner(), owner, "Pool: owner mismatch");
        assertEq(controller.isPool(address(newPool)), true, "pool is not registered");
    }

    function testCreatePoolWithOwnedList() public {
        vm.prank(owner);
        OwnableProjectList newList = OwnableProjectList(controller.createProjectList("New list"));

        bytes memory initCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(mimeToken), address(newList), params)
        );

        vm.prank(owner);
        OsmoticPool newPool = OsmoticPool(controller.createOsmoticPool(initCall));

        assertEq(newList.owner(), owner, "List: owner mismatch");
        assertEq(controller.isList(address(newList)), true, "list is not registered");
        assertEq(newPool.owner(), owner, "Pool: owner mismatch");
        assertEq(controller.isPool(address(newPool)), true, "pool is not registered");
    }

    function testCreateOsmoticPoolWithListNotRegistered() public {
        OwnableProjectList projectList = OwnableProjectList(address(20));

        bytes memory initCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(mimeToken), address(projectList), params)
        );

        vm.expectRevert(abi.encodeWithSelector(InvalidProjectList.selector));

        controller.createOsmoticPool(initCall);
    }

    function testCreateOsmoticPoolWithMimeTokenNotRegistered() public {
        bytes memory mimeInitCall =
            abi.encodeCall(MimeToken.initialize, ("Mime Token", "MIME", merkleRoot, block.timestamp, 1 days));
        address unregisteredMime = mimeTokenFactory.createMimeToken(mimeInitCall);

        bytes memory poolInitCall =
            abi.encodeCall(OsmoticPool.initialize, (address(fundingToken), unregisteredMime, address(registry), params));

        vm.expectRevert(abi.encodeWithSelector(InvalidMimeToken.selector));

        controller.createOsmoticPool(poolInitCall);
    }

    function testCreateMimeToken() public {
        bytes memory initCall = abi.encodeCall(
            MimeToken.initialize,
            (
                "Mime Token",
                "MIME",
                0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d,
                controller.claimTimestamp(),
                controller.claimDuration()
            )
        );
        MimeToken newToken = MimeToken(controller.createMimeToken(initCall));

        assertEq(controller.isToken(address(newToken)), true, "token is not registered");
        assertEq(newToken.owner(), deployer, "token owner mismatch");
    }

    function testCreateMimeTokenWithWrongArgs() public {
        bytes memory initCall = abi.encodeCall(
            MimeToken.initialize,
            (
                "Mime Token",
                "MIME",
                0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d,
                block.timestamp - 1,
                controller.claimDuration()
            )
        );

        vm.expectRevert("OsmoticController: Invalid timestamp for token");

        controller.createMimeToken(initCall);

        initCall = abi.encodeCall(
            MimeToken.initialize,
            (
                "Mime Token",
                "MIME",
                0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d,
                controller.claimTimestamp(),
                3 weeks
            )
        );

        vm.expectRevert("OsmoticController: Invalid round duration for token");

        controller.createMimeToken(initCall);
    }
}
