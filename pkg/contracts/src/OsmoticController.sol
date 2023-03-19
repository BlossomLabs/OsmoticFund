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
    address public immutable projectRegistry;
    address public immutable mimeTokenFactory;
    UpgradeableBeacon public immutable beacon;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;
    mapping(address => bool) public isToken;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);

    constructor(uint256 _version, address _osmoticPool, address _projectRegistry, address _mimeTokenFactory) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_osmoticPool);
        // We transfer the ownership of the beacon to the deployer
        beacon.transferOwnership(msg.sender);

        version = _version;
        deploymentTimestamp = block.timestamp;
        projectRegistry = _projectRegistry;
        mimeTokenFactory = _mimeTokenFactory;
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
    /* ** Creation Functions                                                                                                             ***/
    /* *************************************************************************************************************************************/
    function createPool(
        address _fundingToken,
        address _projectList,
        bytes calldata _governanceTokenInitPayload,
        OsmoticParams calldata _params
    ) external whenNotPaused returns (address token_, address pool_) {
        token_ = createMimeToken(_governanceTokenInitPayload);

        bytes memory initCall = abi.encodeCall(OsmoticPool.initialize, (_fundingToken, token_, _projectList, _params));
        pool_ = createOsmoticPool(initCall);
    }

    function createOsmoticPool(bytes memory _initPayload) public whenNotPaused returns (address pool_) {
        pool_ = address(new BeaconProxy(address(beacon), _initPayload));
        isPool[pool_] = true;

        emit OsmoticPoolCreated(pool_);
    }

    function createProjectList(string calldata name) public whenNotPaused returns (address list_) {
        list_ = address(new OwnableProjectList(projectRegistry, msg.sender, name));
        isList[list_] = true;

        emit ProjectListCreated(list_);
    }

    function createMimeToken(bytes calldata _initPayload) public whenNotPaused returns (address token_) {
        // We avoid emitting the creation event as it is already emitted by the MimeTokenFactory
        token_ = MimeTokenFactory(mimeTokenFactory).createMimeToken(_initPayload);
        MimeToken(token_).transferOwnership(msg.sender);

        isToken[token_] = true;
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function isTokenAllowed(address _token) external view returns (bool) {
        return isToken[_token] || MimeTokenFactory(mimeTokenFactory).isMimeToken(_token);
    }
}
