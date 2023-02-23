// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {IMimeToken} from "mime-token/IMimeToken.sol";

import {SetupScript} from "./SetupScript.s.sol";

import {OsmoticController} from "../src/OsmoticController.sol";
import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";

import {ISuperToken} from "../src/interfaces/ISuperToken.sol";
import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";

contract Dummy {}

contract BaseSetup is SetupScript {
    // fork env
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envOr("GOERLI_RPC_URL", string("https://rpc.ankr.com/eth_goerli"));
    // we use goerli address to test dependencies in the fork chain
    address cfaV1ForwarderAddress = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    address fundingTokenAddress = 0x668168D45eEf326E0E746c86e11b212492Dd8309; // DAIx
    address tokensOwner = 0x5CfAdf589a694723F9Ed167D647582B3Db3b33b3;

    // tokens
    ISuperToken fundingToken;
    IMimeToken governanceToken;

    // dependencies
    ICFAv1Forwarder cfaForwarder;

    // osmotic contracts
    OsmoticController controller;
    ProjectRegistry registry;

    // env
    uint256 version = 1;
    bytes32 merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
    address deployer = address(this);
    address notAuthorized = address(200);
    address registryImplementation;
    address osmoticPoolImplementation;
    address controllerImplementation;

    function setUp() public virtual {
        // if in fork mode create and select fork
        vm.createSelectFork(GOERLI_RPC_URL);

        // labels
        vm.label(deployer, "deployer");
        vm.label(notAuthorized, "notAuthorized");
        vm.label(tokensOwner, "tokensOwner");
        vm.label(cfaV1ForwarderAddress, "cfaForwarder");
        vm.label(fundingTokenAddress, "fundingToken");

        // init dependencies
        fundingToken = ISuperToken(fundingTokenAddress);
        cfaForwarder = ICFAv1Forwarder(cfaV1ForwarderAddress);

        // deploy registry
        (address registryProxy, address registryImplementationAddress) =
            setUpContracts(abi.encode(uint256(1)), "ProjectRegistry", abi.encodeCall(ProjectRegistry.initialize, ()));
        registryImplementation = registryImplementationAddress;
        registry = ProjectRegistry(registryProxy);

        // deploy controller
        // We create a dummy contract to be used as the init beacon implementation
        Dummy dummy = new Dummy();
        (address proxy, address controllerImplementationAddress) = setUpContracts(
            abi.encode(uint256(1), address(dummy), address(registry)),
            "OsmoticController",
            abi.encodeCall(OsmoticController.initialize, ())
        );
        controllerImplementation = controllerImplementationAddress;
        controller = OsmoticController(proxy);

        // now that we have the controller proxy we upgrade the beacon implementation to OsmoticPool
        osmoticPoolImplementation = setUpContract("OsmoticPool", abi.encode(address(cfaForwarder), address(controller)));
        UpgradeableBeacon beacon = UpgradeableBeacon(controller.beacon());
        beacon.upgradeTo(osmoticPoolImplementation);

        // deploy governance token
        governanceToken = IMimeToken(controller.createMimeToken("Osmotic", "OSMO", merkleRoot));

        vm.label(address(registry), "registry");
        vm.label(address(controller), "controller");
        vm.label(address(governanceToken), "governanceToken");
    }
}
