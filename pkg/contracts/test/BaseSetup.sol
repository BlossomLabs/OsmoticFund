// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {SetupScript} from "../script/SetupScript.sol";

import {OsmoticController} from "../src/OsmoticController.sol";
import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";

import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";
import {IStakingFactory} from "../src/interfaces/IStakingFactory.sol";

contract BaseSetup is SetupScript {
    // fork env
    // uint256 goerliFork;
    // string GOERLI_RPC_URL = vm.envString("GOERLI_RPC_URL");
    // we use goerli address to test dependencies in the fork chain
    address cfaV1ForwarderAddress = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    address stakingFactoryAddress = 0x0C685827eFe3551291Fb7De853BfDb02C3eDF3a3;

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
        // create forks
        // goerliFork = vm.createFork(GOERLI_RPC_URL);

        // labels
        vm.label(deployer, "deployer");
        vm.label(notAuthorized, "notAuthorized");

        // init dependencies
        ICFAv1Forwarder cfaForwarder = ICFAv1Forwarder(cfaV1ForwarderAddress);
        IStakingFactory stakingFactory = IStakingFactory(stakingFactoryAddress);

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
