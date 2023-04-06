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
    address fundingTokenAddress = 0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00; // DAIx

    // tokens
    ISuperToken fundingToken;
    MimeToken mimeToken;

    // TODO: This whole mime setup should be imported from the Mime Token repo
    // token holders
    address mimeHolder0 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address mimeHolder2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address unclaimedMimeHolder3 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // merkle proofs
    bytes32[][4] holdersProofs = [
        [
            bytes32(0x11079118024000df209172a1af6eb7a9ea4e5b2bd6e2760481566ce6bee3e0cd),
            bytes32(0xf46478da86f39b5d4f0af753bbc54ab402404b5ed5369f359e8fb24268b12edc)
        ],
        [bytes32(0x0), bytes32(0x0)],
        [
            bytes32(0x9224c4ad0c0d0ea48b770992025547eff95b06645c92f0c047c9d7c161de8091),
            bytes32(0x0627178dd800c957efbe02c61cf32bcab724b4e87b735d34f03e6766ca038c10)
        ],
        [
            bytes32(0x2da52479032a949acaa5138ddd9cf15898df48085ce832cb5fad7367f7bd3cac),
            bytes32(0x0627178dd800c957efbe02c61cf32bcab724b4e87b735d34f03e6766ca038c10)
        ]
    ];

    uint256 currentRound = 0;

    uint256 unclaimedAmount = 0x3635c9adc5dea00000;

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
    uint256 roundDuration = 2 weeks;
    OsmoticParams params = OsmoticParams({
        decay: 999999197747000000, // 10 days (864000 seconds) to reach 50% of targetRate
        drop: 2,
        maxFlow: 19290123456, // 5% of Common Pool per month = Math.floor(0.05e18 / (30 * 24 * 60 * 60))
        minStakeRatio: 25000000000000000 // 2.5% of Total Support = the minimum stake to start receiving funds
    });

    function setUp() public virtual {
        // if in fork mode create and select fork
        vm.createSelectFork(GOERLI_RPC_URL);

        // labels
        vm.label(deployer, "deployer");
        vm.label(notAuthorized, "notAuthorized");
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
        vm.label(address(registry), "registry");

        // deploy controller
        // We create a dummy contract to be used as the init beacon implementation
        Dummy dummy = new Dummy();

        constructorArgs = abi.encode(uint256(1), address(dummy), address(registry), address(mimeTokenFactory));
        controllerImplementation = setUpContract("OsmoticController", constructorArgs);
        address controllerProxy =
            setUpProxy(controllerImplementation, abi.encodeCall(OsmoticController.initialize, (roundDuration)));
        controller = OsmoticController(controllerProxy);
        vm.label(address(controller), "controller");

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
        vm.label(address(mimeToken), "mimeToken");

        mimeToken.claim(0, mimeHolder0, unclaimedAmount, holdersProofs[0]);
        mimeToken.claim(2, mimeHolder2, unclaimedAmount, holdersProofs[2]);

        bytes memory poolInitCall = abi.encodeCall(
            OsmoticPool.initialize, (address(fundingToken), address(mimeToken), address(registry), params)
        );
        pool = OsmoticPool(controller.createOsmoticPool(poolInitCall));
        vm.label(address(pool), "pool");
    }
}
