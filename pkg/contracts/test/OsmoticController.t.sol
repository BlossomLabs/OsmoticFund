// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {SetupScript} from "../script/SetupScript.sol";

import {OsmoticController} from "../src/OsmoticController.sol";
import {InvalidProjectList, OsmoticPool, OsmoticParams} from "../src/OsmoticPool.sol";

import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";
import {
    OwnableProjectList,
    ProjectAlreadyInList,
    ProjectDoesNotExist,
    ProjectNotInList
} from "../src/projects/OwnableProjectList.sol";

import {ISuperToken} from "../src/interfaces/ISuperToken.sol";
import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";
import {Project, IProjectList} from "../src/interfaces/IProjectList.sol";
import {IStakingFactory} from "../src/interfaces/IStakingFactory.sol";

contract OsmoticControllerTest is Test, SetupScript {
    OsmoticController controller;
    OsmoticPool pool;
    ProjectRegistry registry;

    address deployer = address(this);

    uint256 version = 1;

    address osmoticPoolImplementation;
    address controllerImplementation;

    ICFAv1Forwarder cfaForwarder = ICFAv1Forwarder(address(10));
    IStakingFactory stakingFactory = IStakingFactory(address(11));
    ISuperToken fundingToken = ISuperToken(address(12));
    IERC20 governanceToken = IERC20(address(13));
    IProjectList ownedList = IProjectList(address(14));

    OsmoticParams params = OsmoticParams({decay: 1, drop: 2, maxFlow: 3, minStakeRatio: 4});

    // account
    address notAuthorized = address(4);

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    function setUp() public {
        (address registryProxy,) =
            setUpContracts(abi.encode(uint256(1)), "ProjectRegistry", abi.encodeCall(ProjectRegistry.initialize, ()));

        registry = ProjectRegistry(registryProxy);

        osmoticPoolImplementation = setUpContract("OsmoticPool", abi.encode(address(cfaForwarder)));

        (address proxy, address implementation) = setUpContracts(
            abi.encode(uint256(1), osmoticPoolImplementation, address(registry), address(stakingFactory)),
            "OsmoticController",
            abi.encodeCall(OsmoticController.initialize, ())
        );

        controllerImplementation = implementation;

        controller = OsmoticController(proxy);

        vm.label(notAuthorized, "notAuthorized");
        vm.label(deployer, "deployer");
    }

    function testInitialize() public {
        assertEq(controller.version(), 1, "version mismatch");
        assertEq(registry.owner(), deployer, "owner mismatch");
        assertEq(controller.implementation(), controllerImplementation, "implementation mismatch");
        assertEq(controller.osmoticPoolImplementation(), osmoticPoolImplementation, "poolImplementation mismatch");
        assertEq(controller.projectRegistry(), address(registry), "projectRegistry mismatch");
        assertEq(controller.isList(address(registry)), true, "registry not set as default list");
        assertEq(address(controller.stakingFactory()), address(stakingFactory), "stakingFactory mismatch");
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
        address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12)));

        UpgradeableBeacon beacon = UpgradeableBeacon(controller.osmoticPoolImplementation());

        beacon.upgradeTo(newImplementation);

        assertEq(controller.osmoticPoolImplementation(), newImplementation, "poolImplementation mismatch");
    }

    function testCreatePool() public {
        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (controller, fundingToken, governanceToken, registry, params));

        address newPool = controller.createOsmoticPool(initCall);

        assertEq(controller.isPool(newPool), true, "new pool is not registered");
    }

    function testCreatePoolWithListNotRegistered() public {
        IProjectList projectList = IProjectList(address(20));

        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (controller, fundingToken, governanceToken, projectList, params));

        vm.expectRevert(abi.encodeWithSelector(InvalidProjectList.selector));

        controller.createOsmoticPool(initCall);
    }

    function testCreateOwnedList() public {
        address newList = controller.createProjectList("New list");

        assertEq(controller.isList(newList), true, "new list is not registered");
    }

    function testCreatePoolWithOwnedList() public {
        IProjectList newList = IProjectList(controller.createProjectList("New list"));

        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (controller, fundingToken, governanceToken, newList, params));

        address newPool = controller.createOsmoticPool(initCall);

        assertEq(controller.isPool(newPool), true, "new pool is not registered");
    }
}
