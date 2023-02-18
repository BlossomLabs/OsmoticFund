// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {SetupScript} from "./SetupScript.sol";

import {OsmoticController} from "../src/OsmoticController.sol";
import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";

import {ISuperToken} from "../src/interfaces/ISuperToken.sol";
import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";
import {IStakingFactory} from "../src/interfaces/IStakingFactory.sol";

contract BaseSetup is SetupScript {
    // fork env
    uint256 goerliFork;
    string GOERLI_RPC_URL = vm.envOr("GOERLI_RPC_URL", string("https://rpc.ankr.com/eth_goerli"));
    // we use goerli address to test dependencies in the fork chain
    address cfaV1ForwarderAddress = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    address stakingFactoryAddress = 0x0C685827eFe3551291Fb7De853BfDb02C3eDF3a3;
    address fundingTokenAddress = 0x668168D45eEf326E0E746c86e11b212492Dd8309; // DAIx
    address governanceTokenAddress = 0xa625BEDDA5c4d25A67aEccD9dc8c4b70D9f77E1f; // HNYT
    address tokensOwner = 0x5CfAdf589a694723F9Ed167D647582B3Db3b33b3;

    // tokens
    ISuperToken fundingToken;
    IERC20 governanceToken;

    // dependencies
    IStakingFactory stakingFactory;
    ICFAv1Forwarder cfaForwarder;

    // osmotic contracts
    OsmoticController controller;
    ProjectRegistry registry;

    // env
    uint256 version = 1;
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
        vm.label(stakingFactoryAddress, "stakingFactory");
        vm.label(fundingTokenAddress, "fundingToken");
        vm.label(governanceTokenAddress, "governanceToken");

        // deploy tokens
        fundingToken = ISuperToken(fundingTokenAddress);
        governanceToken = IERC20(governanceTokenAddress);

        // init dependencies
        cfaForwarder = ICFAv1Forwarder(cfaV1ForwarderAddress);
        stakingFactory = IStakingFactory(stakingFactoryAddress);

        // deploy registry
        (address registryProxy, address registryImplementationAddress) =
            setUpContracts(abi.encode(uint256(1)), "ProjectRegistry", abi.encodeCall(ProjectRegistry.initialize, ()));
        registryImplementation = registryImplementationAddress;
        registry = ProjectRegistry(registryProxy);

        // deploy controller
        osmoticPoolImplementation = setUpContract("OsmoticPool", abi.encode(address(cfaForwarder)));
        (address proxy, address controllerImplementationAddress) = setUpContracts(
            abi.encode(uint256(1), osmoticPoolImplementation, address(registry), address(stakingFactory)),
            "OsmoticController",
            abi.encodeCall(OsmoticController.initialize, ())
        );
        controllerImplementation = controllerImplementationAddress;
        controller = OsmoticController(proxy);
    }
}
