// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {UpgradeScripts} from "upgrade-scripts/UpgradeScripts.sol";
import {ERC1967Proxy} from "@oz/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@oz/proxy/utils/UUPSUpgradeable.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";
import {MimeToken} from "mime-token/MimeToken.sol";
import {MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

import {OsmoticController} from "./OsmoticController.sol";
import {OsmoticParams} from "./OsmoticFormula.sol";
import {OsmoticPool} from "./OsmoticPool.sol";
import {OwnableProjectList} from "./projects/OwnableProjectList.sol";
import {ProjectRegistry} from "./projects/ProjectRegistry.sol";

// TODO: remove this after abstracting out the osmotic pool creation logic to a factory
contract Dummy {}

struct SetupConfig {
    uint256 version;
    uint256 roundDuration;
    address cfaV1Forwarder;
}

abstract contract SetupScript is UpgradeScripts {
    /// @dev using OZ's ERC1967Proxy
    function getDeployProxyCode(address _implementation, bytes memory _initCall)
        internal
        pure
        override
        returns (bytes memory)
    {
        return abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_implementation, _initCall));
    }

    /// @dev using OZ's UUPSUpgradeable function call
    function upgradeProxy(address _proxy, address _newImplementation) internal override {
        UUPSUpgradeable(_proxy).upgradeTo(_newImplementation);
    }

    // /// @dev override using forge's built-in create2 deployer (only works for specific chains, or: use your own!)
    // function deployCode(bytes memory code) internal override returns (address addr) {
    //     uint256 salt = 0x1234;

    //     assembly {
    //         addr := create2(0, add(code, 0x20), mload(code), salt)
    //     }
    // }

    function setUpContracts(SetupConfig memory _config) public {
        address mimeTokenFactory = createMimeTokenFactory();

        (, address projectRegistryAddress) = createProjectRegistry(_config.version);

        (, address osmoticControllerAddress) = createOsmoticControllerAndPoolImpl(
            _config.version, projectRegistryAddress, mimeTokenFactory, _config.roundDuration, _config.cfaV1Forwarder
        );
    }

    function createOsmoticControllerAndPoolImpl(
        uint256 _version,
        address _projectRegistry,
        address _mimeTokenFactory,
        uint256 _claimDuration,
        address _poolCFAForwarder
    ) public returns (address impl_, address controllerProxy_) {
        (impl_, controllerProxy_) =
            createOsmoticController(_version, address(new Dummy()), _projectRegistry, _mimeTokenFactory, _claimDuration);

        address osmoticPoolImpl = createOsmoticPoolImplementation(_poolCFAForwarder, controllerProxy_);

        UpgradeableBeacon beacon = UpgradeableBeacon(OsmoticController(controllerProxy_).beacon());
        beacon.upgradeTo(osmoticPoolImpl);
    }

    function createOsmoticController(
        uint256 _version,
        address _osmoticPool,
        address _projectRegistry,
        address _mimeTokenFactory,
        uint256 _claimDuration
    ) public returns (address impl_, address controllerProxy_) {
        bytes memory constructorArgs = abi.encode(_version, _osmoticPool, _projectRegistry, _mimeTokenFactory);
        impl_ = setUpContract("OsmoticController", constructorArgs);
        vm.label(impl_, "osmoticControllerImp");

        controllerProxy_ = setUpProxy(impl_, abi.encodeCall(OsmoticController.initialize, (_claimDuration)));
        vm.label(controllerProxy_, "osmoticController");
    }

    function createProjectRegistry(uint256 _version) public returns (address impl_, address projectRegistryProxy_) {
        bytes memory constructorArgs = abi.encode(_version);
        impl_ = setUpContract("ProjectRegistry", constructorArgs);
        vm.label(impl_, "projectRegistryImpl");

        projectRegistryProxy_ = setUpProxy(impl_, abi.encodeCall(ProjectRegistry.initialize, ()));
        vm.label(projectRegistryProxy_, "projectRegistry");
    }

    function createMimeTokenFactory() public returns (address mimeTokenFactory_) {
        address mimeTokenImpl = address(new MimeToken());
        vm.label(mimeTokenImpl, "mimeTokenImpl");

        mimeTokenFactory_ = address(new MimeTokenFactory(mimeTokenImpl));
        vm.label(mimeTokenFactory_, "mimeTokenFactory");
    }

    function createMimeTokenFromController(address _osmoticController, bytes32 _merkleRoot)
        public
        returns (address mimeToken_)
    {
        OsmoticController osmoticController = OsmoticController(_osmoticController);
        bytes memory tokenInitCall = abi.encodeCall(
            MimeToken.initialize,
            ("Osmotic Fund", "OF", _merkleRoot, osmoticController.claimTimestamp(), osmoticController.claimDuration())
        );

        mimeToken_ = osmoticController.createMimeToken(tokenInitCall);
        vm.label(mimeToken_, "mimeToken");
    }

    function createOsmoticPoolImplementation(address _cfaForwarder, address _osmoticController)
        public
        returns (address impl_)
    {
        bytes memory constructorArgs = abi.encode(_cfaForwarder, _osmoticController);
        impl_ = setUpContract("OsmoticPool", constructorArgs);
        vm.label(impl_, "osmoticPoolImpl");
    }

    function createOsmoticPoolFromController(
        address _osmoticController,
        address _fundingToken,
        address _mimeToken,
        address _projectList,
        OsmoticParams memory _osmoticParams
    ) public returns (address osmoticPool_) {
        bytes memory poolInitCall =
            abi.encodeCall(OsmoticPool.initialize, (_fundingToken, _mimeToken, _projectList, _osmoticParams));

        osmoticPool_ = OsmoticController(_osmoticController).createOsmoticPool(poolInitCall);
        vm.label(osmoticPool_, "osmoticPool");
    }

    function createOwnableProjectList(address _projectRegistry, string memory _name) public returns (address) {
        bytes memory constructorArgs = abi.encode(_projectRegistry, _name);

        return setUpContract("OwnableProjectList", constructorArgs);
    }
}
