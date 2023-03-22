// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {MimeToken} from "mime-token/MimeToken.sol";
import {MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

import {SetupScript} from "./SetupScript.s.sol";

import {OsmoticController} from "../src/OsmoticController.sol";
import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";
import {OsmoticPool, OsmoticParams} from "../src/OsmoticPool.sol";

import {ISuperToken} from "../src/interfaces/ISuperToken.sol";
import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";

contract Dummy {}

contract BaseSetup is SetupScript {
    // fork env
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envOr("GOERLI_RPC_URL", string("https://rpc.ankr.com/eth_goerli"));
    // we use goerli address to test dependencies in the fork chain
    address cfaV1ForwarderAddress = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    address mimeTokenFactoryAddress = 0x3D1Bebcfc55192bF6eE9E94F0EBA2fb54D5423aC;
    address fundingTokenAddress = 0x668168D45eEf326E0E746c86e11b212492Dd8309; // DAIx
    address tokensOwner = 0x5CfAdf589a694723F9Ed167D647582B3Db3b33b3;

    // tokens
    ISuperToken fundingToken;
    MimeToken mimeToken;

    // dependencies
    ICFAv1Forwarder cfaForwarder;
    MimeTokenFactory mimeTokenFactory;

    // osmotic contracts
    OsmoticController controller;
    ProjectRegistry registry;
    OsmoticPool pool;

    // env
    address deployer = address(this);
    address notAuthorized = address(200);
    address registryImplementation;
    address osmoticPoolImplementation;
    address controllerImplementation;

    // init data
    uint256 version = 1;
    bytes32 merkleRoot = 0x47c52ef48ec180964d648c3783e0b02202f16211392b986fbe2627f021657f2b; // init with: https://gist.github.com/0xGabi/4ca04edae9753ec32ffed7dc0cffe31e
    uint256 roundDuration = 1 weeks;
    OsmoticParams params = OsmoticParams({decay: 1, drop: 2, maxFlow: 3, minStakeRatio: 4});

    function setUp() public virtual {
        // if in fork mode create and select fork
        vm.createSelectFork(GOERLI_RPC_URL);

        // labels
        vm.label(deployer, "deployer");
        vm.label(notAuthorized, "notAuthorized");
        vm.label(tokensOwner, "tokensOwner");
        vm.label(cfaV1ForwarderAddress, "cfaForwarder");
        vm.label(mimeTokenFactoryAddress, "mimeTokenFactory");
        vm.label(fundingTokenAddress, "fundingToken");

        // init dependencies
        fundingToken = ISuperToken(fundingTokenAddress);
        cfaForwarder = ICFAv1Forwarder(cfaV1ForwarderAddress);
        mimeTokenFactory = MimeTokenFactory(mimeTokenFactoryAddress);

        // deploy registry
        bytes memory constructorArgs = abi.encode(uint256(1));
        registryImplementation = setUpContract("ProjectRegistry", constructorArgs);
        address registryProxy = setUpProxy(registryImplementation, abi.encodeCall(ProjectRegistry.initialize, ()));
        registry = ProjectRegistry(registryProxy);

        // deploy controller
        // We create a dummy contract to be used as the init beacon implementation
        Dummy dummy = new Dummy();

        constructorArgs = abi.encode(uint256(1), address(dummy), address(registry), address(mimeTokenFactory));
        controllerImplementation = setUpContract("OsmoticController", constructorArgs);
        address controllerProxy =
            setUpProxy(controllerImplementation, abi.encodeCall(OsmoticController.initialize, (roundDuration)));
        controller = OsmoticController(controllerProxy);

        // now that we have the controller proxy we upgrade the beacon implementation to OsmoticPool
        osmoticPoolImplementation = setUpContract("OsmoticPool", abi.encode(address(cfaForwarder), address(controller)));
        UpgradeableBeacon beacon = UpgradeableBeacon(controller.beacon());
        beacon.upgradeTo(osmoticPoolImplementation);

        // deploy token
        bytes memory tokenInitCall = abi.encodeCall(
            MimeToken.initialize,
            ("Osmotic Fund", "OF", merkleRoot, controller.claimTimestamp(), controller.claimDuration())
        );
        mimeToken = MimeToken(controller.createMimeToken(tokenInitCall));

        bytes memory poolInitCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(mimeToken), address(registry), params)
        );
        pool = OsmoticPool(controller.createOsmoticPool(poolInitCall));

        vm.label(address(registry), "registry");
        vm.label(address(controller), "controller");
        vm.label(address(mimeToken), "mimeToken");
        vm.label(address(pool), "pool");
    }
}
