// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {MimeToken} from "mime-token/MimeToken.sol";

import {OwnableProjectList} from "./projects/OwnableProjectList.sol";

import {OsmoticPool} from "./OsmoticPool.sol";

contract OsmoticController is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    uint256 public immutable version;
    UpgradeableBeacon public immutable beacon;
    address public immutable projectRegistry;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;
    mapping(address => bool) public isToken;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event TokenCreated(address indexed token);

    constructor(uint256 _version, address _initImplementation, address _projectRegistry) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_initImplementation);
        // We transfer the ownership of the beacon to the deployer
        beacon.transferOwnership(msg.sender);

        version = _version;
        projectRegistry = _projectRegistry;
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
    /* ** Pool Creation Function                                                                                                         ***/
    /* *************************************************************************************************************************************/

    function createOsmoticPool(bytes calldata _poolInitPayload) external whenNotPaused returns (address pool_) {
        pool_ = address(new BeaconProxy(address(beacon), _poolInitPayload));
        isPool[pool_] = true;

        emit OsmoticPoolCreated(pool_);
    }

    /* *************************************************************************************************************************************/
    /* ** Project List Creation Function                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function createProjectList(string calldata name) external whenNotPaused returns (address list_) {
        list_ = address(new OwnableProjectList(projectRegistry, msg.sender, name));
        isList[list_] = true;

        emit ProjectListCreated(list_);
    }

    /* *************************************************************************************************************************************/
    /* ** Mime Token Creation Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

    function createMimeToken(string calldata name, string calldata symbol, bytes32 merkleRoot)
        external
        whenNotPaused
        returns (address token_)
    {
        MimeToken token = new MimeToken(name, symbol, merkleRoot);
        token.transferOwnership(msg.sender);

        token_ = address(token);
        isToken[token_] = true;

        emit TokenCreated(token_);
    }
}
