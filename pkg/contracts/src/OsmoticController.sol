// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

import {IStakingFactory} from "./interfaces/IStakingFactory.sol";
import {ILockManager} from "./interfaces/ILockManager.sol";
import {IStaking} from "./interfaces/IStaking.sol";

import {OwnableProjectList} from "./projects/OwnableProjectList.sol";

import {OsmoticPool} from "./OsmoticPool.sol";

error NotOsmoticPool();

contract OsmoticController is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, ILockManager {
    using SafeERC20 for IERC20;

    uint256 public immutable version;
    UpgradeableBeacon public immutable beacon;
    address public immutable projectRegistry;
    IStakingFactory public immutable stakingFactory; // For finding each collateral token's staking pool and locking/unlocking tokens

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;

    // users => tokens => amounts
    mapping(address => mapping(address => uint256)) internal userLockedBalance; // The amount of locked tokens a user has

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event UserLockedBalanceChanged(address indexed user, address indexed token, uint256 amount);

    /* *************************************************************************************************************************************/
    /* ** Modifiers                                                                                                                      ***/
    /* *************************************************************************************************************************************/

    modifier onlyPool(address _pool) {
        if (!isPool[_pool]) {
            revert NotOsmoticPool();
        }

        _;
    }

    constructor(
        uint256 _version,
        address _initImplementation,
        address _projectRegistry,
        IStakingFactory _stakingFactory
    ) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_initImplementation);
        // We transfer the ownership of the beacon to the deployer
        beacon.transferOwnership(msg.sender);

        version = _version;
        projectRegistry = _projectRegistry;
        stakingFactory = _stakingFactory;
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
    /* ** Pool Creation Function                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function createOsmoticPool(bytes calldata _poolInitPayload) external whenNotPaused returns (address pool_) {
        pool_ = address(new BeaconProxy(address(beacon), _poolInitPayload));
        isPool[pool_] = true;

        emit OsmoticPoolCreated(pool_);
    }

    /* *************************************************************************************************************************************/
    /* ** Project List Creation Function                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function createProjectList(string calldata name) external whenNotPaused returns (address list_) {
        list_ = address(new OwnableProjectList(projectRegistry, msg.sender, name));
        isList[list_] = true;

        emit ProjectListCreated(list_);
    }

    /* *************************************************************************************************************************************/
    /* ** Locking Functions                                                                                                              ***/
    /* *************************************************************************************************************************************/

    function unlockBalance(address _token, address _user, uint256 _amount) external whenNotPaused {
        IStaking staking = stakingFactory.getOrCreateInstance(_token);
        (uint256 currentLocked,) = staking.getLock(_user, address(this));

        uint256 availableUnlock = currentLocked - userLockedBalance[_user][_token];

        require(_amount <= availableUnlock, "OsmoticController: amount to unlock is greater than available");

        _unlockBalance(staking, _user, _amount);
    }

    function updateLockedBalance(address _token, address _user, uint256 _amount, address _pool)
        external
        whenNotPaused
        onlyPool(_pool)
    {
        uint256 currentLockedBalance = userLockedBalance[_user][_token];

        // We only store the balance if it is the maximum amount of locked tokens
        // across all the pools that has _token as governance token
        if (_amount > currentLockedBalance) {
            IStaking staking = stakingFactory.getOrCreateInstance(_token);
            _lockBalance(staking, _user, _amount - currentLockedBalance);
            userLockedBalance[_user][_token] = _amount;
            emit UserLockedBalanceChanged(_user, _token, _amount);
        }
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    /**
     * @dev ILockManager conformance.
     *      The Staking contract checks this on each request to unlock an amount managed by this LockManager.
     *      Check the user locked balance for the staking token and disable owners from unlocking their funds
     *      when amount is great than avaiable to unlock.
     * @return Whether the request to unlock tokens of a given owner should be allowed
     */
    function canUnlock(address _user, uint256 _amount) external view returns (bool) {
        // we assume that msg.sender is the staking contract
        IStaking staking = IStaking(msg.sender);

        (uint256 currentLocked,) = staking.getLock(_user, address(this));

        uint256 availableUnlock = currentLocked - userLockedBalance[_user][staking.token()];

        return _amount <= availableUnlock;
    }

    /**
     * @dev Tell details of a `_user`'s lock managed by the controller for a given `_token`
     * @param _token Token
     * @param _user Address
     * @return locked Amount of locked tokens
     * @return allowance Amount of tokens that the controller is allowed to lock
     */
    function getStakingLock(address _token, address _user) public view returns (uint256 locked, uint256 allowance) {
        IStaking staking = stakingFactory.getInstance(_token);

        (locked, allowance) = staking.getLock(_user, address(this));
    }

    function getLockedBalance(address _token, address _user) external view returns (uint256) {
        return userLockedBalance[_user][_token];
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Locking Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/

    /**
     * @dev Lock some tokens in the staking pool for a user
     * @param _staking Staking pool for the ERC20 token to be locked
     * @param _user Address of the user to lock tokens for
     * @param _amount Amount of collateral tokens to be locked
     */
    function _lockBalance(IStaking _staking, address _user, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        _staking.lock(_user, _amount);
    }

    /**
     * @dev Unlock some tokens in the staking pool for a user
     * @param _staking Staking pool for the ERC20 token to be unlocked
     * @param _user Address of the user to unlock tokens for
     * @param _amount Amount of collateral tokens to be unlocked
     */
    function _unlockBalance(IStaking _staking, address _user, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        _staking.unlock(_user, address(this), _amount);
    }
}
