// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {NotOsmoticPool} from "../src/OsmoticController.sol";
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

        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (fundingToken, governanceToken, registry, params));

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

    function testWhenNotPausedModifier() public {
        controller.pause();
        vm.expectRevert("Pausable: paused");

        controller.createOsmoticPool(bytes(""));
    }

    function testUpdateOsmoticPoolImplementation() public {
        address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));
        UpgradeableBeacon beacon = UpgradeableBeacon(controller.beacon());
        beacon.upgradeTo(newImplementation);

        assertEq(controller.osmoticPoolImplementation(), newImplementation, "poolImplementation mismatch");
    }

    function testCreatePool() public {
        assertEq(controller.isPool(address(pool)), true, "new pool is not registered");
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

    function stakingPreTransactions(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= governanceToken.balanceOf(tokensOwner));

        // get staking
        IStaking staking = stakingFactory.getOrCreateInstance(address(governanceToken));

        governanceToken.approve(address(staking), _amount);
        staking.stake(_amount, "");
        staking.allowManager(address(controller), _amount, "");
    }

    function testFuzzUpdateLockedBalance(uint256 _amount) public {
        vm.startPrank(tokensOwner);
        stakingPreTransactions(_amount);
        vm.stopPrank();

        vm.prank(address(pool));
        controller.updateLockedBalance(address(governanceToken), tokensOwner, _amount, address(pool));

        assertEq(controller.getLockedBalance(address(governanceToken), tokensOwner), _amount, "locked balance mismatch");
    }

    function testFuzzUnlockBalance(uint256 _amount) public {}

    function testFuzzCanUnlock(uint256 _amount) public {}
}
