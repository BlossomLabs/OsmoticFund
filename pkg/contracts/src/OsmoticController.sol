// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {MimeToken, MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

import {OwnableProjectList} from "./projects/OwnableProjectList.sol";

import {OsmoticPool, OsmoticParams} from "./OsmoticPool.sol";

contract OsmoticController is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    uint256 public immutable version;
    uint256 public immutable deploymentTimestamp;
    UpgradeableBeacon public immutable beacon;

    address public projectRegistry;
    address public mimeTokenFactory;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;
    mapping(address => bool) public isToken;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ProjectRegistryUpdated(address indexed projectRegistry);
    event MimeTokenFactoryUpdated(address indexed mimeTokenFactory);

    constructor(uint256 _version, address _osmoticPool, address _projectRegistry, address _mimeTokenFactory) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_osmoticPool);
        // We transfer the ownership of the beacon to the deployer
        beacon.transferOwnership(msg.sender);

        version = _version;
        deploymentTimestamp = block.timestamp;
        projectRegistry = _projectRegistry;
        mimeTokenFactory = _mimeTokenFactory;

        emit ProjectRegistryUpdated(_projectRegistry);
        emit MimeTokenFactoryUpdated(_mimeTokenFactory);
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // We set the registry as the default list
        isList[projectRegistry] = true;
    }

    /* *************************************************************************************************************************************/
    /* ** Pausability Functions                                                                                                          ***/
    /* *************************************************************************************************************************************/

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* *************************************************************************************************************************************/
    /* ** Upgradeability Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function osmoticPoolImplementation() external view returns (address) {
        return beacon.implementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* *************************************************************************************************************************************/
    /* ** Setter Functions                                                                                                               ***/
    /* *************************************************************************************************************************************/

    function setProjectRegistry(address _projectRegistry) external onlyOwner {
        projectRegistry = _projectRegistry;
        emit ProjectRegistryUpdated(_projectRegistry);
    }

    function setMimeTokenFactory(address _mimeTokenFactory) external onlyOwner {
        mimeTokenFactory = _mimeTokenFactory;
        emit MimeTokenFactoryUpdated(_mimeTokenFactory);
    }

    /* *************************************************************************************************************************************/
    /* ** Creation Functions                                                                                                             ***/
    /* *************************************************************************************************************************************/

    function createOsmoticPool(bytes calldata _poolInitPayload) public whenNotPaused returns (address pool_) {
        pool_ = address(new BeaconProxy(address(beacon), _poolInitPayload));
        isPool[pool_] = true;

        emit OsmoticPoolCreated(pool_);
    }

    function createProjectList(string calldata name) public whenNotPaused returns (address list_) {
        list_ = address(new OwnableProjectList(projectRegistry, msg.sender, name));
        isList[list_] = true;

        emit ProjectListCreated(list_);
    }

    function createMimeToken(string calldata name, string calldata symbol, bytes32 merkleRoot, uint256 roundDuration)
        external
        whenNotPaused
        returns (address token)
    {
        bytes memory initCall =
            abi.encodeCall(MimeToken.initialize, (name, symbol, merkleRoot, deploymentTimestamp, roundDuration));

        token = MimeTokenFactory(mimeTokenFactory).createMimeToken(initCall);

        MimeToken(token).transferOwnership(msg.sender);

        isToken[token] = true;
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function isTokenAllowed(address _token) external view returns (bool) {
        return MimeTokenFactory(mimeTokenFactory).isMimeToken(_token) || isToken[_token];
    }
}
