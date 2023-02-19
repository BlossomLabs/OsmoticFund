// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {InvalidProjectList, OsmoticPool, OsmoticParams} from "../src/OsmoticPool.sol";

import {IProjectList} from "../src/interfaces/IProjectList.sol";
import {IStaking} from "../src/interfaces/IStaking.sol";

import {BaseSetup} from "../script/BaseSetup.sol";

contract OsmoticControllerTest is Test, BaseSetup {
    OsmoticPool pool;
    OsmoticParams params;

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    function setUp() public override {
        super.setUp();

        params = OsmoticParams({decay: 1, drop: 2, maxFlow: 3, minStakeRatio: 4});
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

    function testCreatePool() public {
        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (fundingToken, governanceToken, registry, params));
        address newPool = controller.createOsmoticPool(initCall);

        assertEq(controller.isPool(newPool), true, "new pool is not registered");
    }

    function testCreatePoolWithListNotRegistered() public {
        IProjectList projectList = IProjectList(address(20));

        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (fundingToken, governanceToken, projectList, params));

        vm.expectRevert(abi.encodeWithSelector(InvalidProjectList.selector));

        controller.createOsmoticPool(initCall);
    }

    function testCreateOwnedList() public {
        address newList = controller.createProjectList("New list");

        assertEq(controller.isList(newList), true, "new list is not registered");
    }

    function testCreatePoolWithOwnedList() public {
        IProjectList newList = IProjectList(controller.createProjectList("New list"));

        bytes memory initCall = abi.encodeCall(OsmoticPool.initialize, (fundingToken, governanceToken, newList, params));

        address newPool = controller.createOsmoticPool(initCall);

        assertEq(controller.isPool(newPool), true, "new pool is not registered");
    }

    function testFuzzLockBalance(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= governanceToken.balanceOf(tokensOwner));

        // get staking
        IStaking staking = stakingFactory.getOrCreateInstance(address(governanceToken));

        vm.startPrank(tokensOwner);
        governanceToken.approve(address(staking), _amount);
        staking.stake(_amount, "");
        staking.allowManager(address(controller), _amount, "");

        controller.lockBalance(address(governanceToken), _amount);

        assertEq(
            controller.getParticipantStaking(tokensOwner, address(governanceToken)), _amount, "locked balance mismatch"
        );
    }
}
