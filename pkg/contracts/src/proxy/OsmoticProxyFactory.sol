// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {ProxyFactory} from "proxy-factory/ProxyFactory.sol";

import {IOsmoticController} from "../interfaces/IOsmoticController.sol";
import {IOsmoticProxied} from "../interfaces/IOsmoticProxied.sol";
import {IOsmoticProxyFactory} from "../interfaces/IOsmoticProxyFactory.sol";

/// @title A Osmotic factory for Proxy contracts that proxy OsmoticProxied implementations.
contract OsmoticProxyFactory is IOsmoticProxyFactory, ProxyFactory {
    address public override controller;

    uint256 public override defaultVersion;

    mapping(address => bool) public override isInstance;

    mapping(uint256 => mapping(uint256 => bool)) public override upgradeEnabledForPath;

    constructor(address controller_) {
        require(IOsmoticController(controller = controller_).owner() != address(0), "OPF:C:INVALID_OWNER");
    }

    modifier onlyOwner() {
        require(msg.sender == IOsmoticController(controller).owner(), "OPF:NOT_OWNER");
        _;
    }

    modifier whenProtocolNotPaused() {
        require(!IOsmoticController(controller).paused(), "OPF:PROTOCOL_PAUSED");
        _;
    }

    /**
     *
     */
    /**
     * Admin Functions                                                                                                                **
     */
    /**
     *
     */

    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) public virtual override onlyOwner {
        require(fromVersion_ != toVersion_, "OPF:DUP:OVERWRITING_INITIALIZER");
        require(_registerMigrator(fromVersion_, toVersion_, address(0)), "OPF:DUP:FAILED");

        emit UpgradePathDisabled(fromVersion_, toVersion_);

        upgradeEnabledForPath[fromVersion_][toVersion_] = false;
    }

    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_)
        public
        virtual
        override
        onlyOwner
    {
        require(fromVersion_ != toVersion_, "OPF:EUP:OVERWRITING_INITIALIZER");
        require(_registerMigrator(fromVersion_, toVersion_, migrator_), "OPF:EUP:FAILED");

        emit UpgradePathEnabled(fromVersion_, toVersion_, migrator_);

        upgradeEnabledForPath[fromVersion_][toVersion_] = true;
    }

    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_)
        public
        virtual
        override
        onlyOwner
    {
        // Version 0 reserved as "no version" since default `defaultVersion` is 0.
        require(version_ != uint256(0), "OPF:RI:INVALID_VERSION");

        emit ImplementationRegistered(version_, implementationAddress_, initializer_);

        require(_registerImplementation(version_, implementationAddress_), "OPF:RI:FAIL_FOR_IMPLEMENTATION");

        // Set migrator for initialization, which understood as fromVersion == toVersion.
        require(_registerMigrator(version_, version_, initializer_), "OPF:RI:FAIL_FOR_MIGRATOR");
    }

    function setDefaultVersion(uint256 version_) public virtual override onlyOwner {
        // Version must be 0 (to disable creating new instances) or be registered.
        require(version_ == 0 || _implementationOf[version_] != address(0), "OPF:SDV:INVALID_VERSION");

        emit DefaultVersionSet(defaultVersion = version_);
    }

    function setController(address controller_) public virtual override onlyOwner {
        require(IOsmoticController(controller_).owner() != address(0), "OPF:SG:INVALID_GLOBALS");

        emit OsmoticControllerSet(controller = controller_);
    }

    /**
     *
     */
    /**
     * Instance Functions                                                                                                             **
     */
    /**
     *
     */

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        public
        virtual
        override
        whenProtocolNotPaused
        returns (address instance_)
    {
        bool success;
        (success, instance_) = _newInstance(arguments_, keccak256(abi.encodePacked(arguments_, salt_)));
        require(success, "OPF:CI:FAILED");

        isInstance[instance_] = true;

        emit InstanceDeployed(defaultVersion, instance_, arguments_);
    }

    // NOTE: The implementation proxied by the instance defines the access control logic for its own upgrade.
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_)
        public
        virtual
        override
        whenProtocolNotPaused
    {
        uint256 fromVersion = _versionOf[IOsmoticProxied(msg.sender).implementation()];

        require(upgradeEnabledForPath[fromVersion][toVersion_], "OPF:UI:NOT_ALLOWED");

        emit InstanceUpgraded(msg.sender, fromVersion, toVersion_, arguments_);

        require(_upgradeInstance(msg.sender, toVersion_, arguments_), "OPF:UI:FAILED");
    }

    /**
     *
     */
    /**
     * View Functions                                                                                                                 **
     */
    /**
     *
     */

    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_)
        public
        view
        virtual
        override
        returns (address instanceAddress_)
    {
        return _getDeterministicProxyAddress(keccak256(abi.encodePacked(arguments_, salt_)));
    }

    function implementationOf(uint256 version_) public view virtual override returns (address implementation_) {
        return _implementationOf[version_];
    }

    function defaultImplementation() external view override returns (address defaultImplementation_) {
        return _implementationOf[defaultVersion];
    }

    function migratorForPath(uint256 oldVersion_, uint256 newVersion_)
        public
        view
        virtual
        override
        returns (address migrator_)
    {
        return _migratorForPath[oldVersion_][newVersion_];
    }

    function versionOf(address implementation_) public view virtual override returns (uint256 version_) {
        return _versionOf[implementation_];
    }
}
