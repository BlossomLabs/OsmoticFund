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
    UpgradeableBeacon public immutable beacon;
    address public immutable projectRegistry;
    address public immutable mimeTokenFactory;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);

    constructor(uint256 _version, address _initImplementation, address _projectRegistry, address _mimeTokenFactory) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_initImplementation);
        // We transfer the ownership of the beacon to the deployer
        beacon.transferOwnership(msg.sender);

        version = _version;
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

    function createOsmoticPool(bytes memory _poolInitPayload) public whenNotPaused returns (address pool_) {
        pool_ = address(new BeaconProxy(address(beacon), _poolInitPayload));
        isPool[pool_] = true;

        emit OsmoticPoolCreated(pool_);
    }

    function createProjectList(string calldata name) public whenNotPaused returns (address list_) {
        list_ = address(new OwnableProjectList(projectRegistry, msg.sender, name));
        isList[list_] = true;

        emit ProjectListCreated(list_);
    }

    function createMimeToken(string calldata name, string calldata symbol, bytes32 merkleRoot)
        external
        whenNotPaused
        returns (address)
    {
        MimeToken token = MimeTokenFactory(mimeTokenFactory).createMimeToken(name, symbol, merkleRoot);
        token.transferOwnership(msg.sender);

        return address(token);
    }

    function createPool(
        string calldata name,
        string calldata symbol,
        bytes32 merkleRoot,
        address fundingToken,
        bool isPrivate,
        OsmoticParams calldata params
    ) external whenNotPaused returns (address pool_) {
        MimeToken governanceToken = MimeTokenFactory(mimeTokenFactory).createMimeToken(name, symbol, merkleRoot);
        governanceToken.transferOwnership(msg.sender);

        address projectList;
        if (isPrivate) {
            projectList = createProjectList(name);
        } else {
            projectList = projectRegistry;
        }

        bytes memory initCall =
            abi.encodeCall(OsmoticPool.initialize, (fundingToken, address(governanceToken), projectList, params));

        pool_ = createOsmoticPool(initCall);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function isToken(address _token) external view returns (bool) {
        return MimeTokenFactory(mimeTokenFactory).isMimeToken(_token);
    }
}
