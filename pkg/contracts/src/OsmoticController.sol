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

import {OsmoticPool, ParticipantSupportUpdate} from "./OsmoticPool.sol";

error NotOsmoticPool();

contract OsmoticController is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, ILockManager {
    using SafeERC20 for IERC20;

    UpgradeableBeacon internal immutable beacon;

    uint256 public immutable version;

    address public immutable projectRegistry;

    IStakingFactory public immutable stakingFactory; // For finding each collateral token's staking pool and locking/unlocking tokens

    mapping(address => bool) public isPool;
    mapping(address => bool) public isList;

    mapping(address => uint256) internal participantSupportedPools; // Amount of pools supported by a participant

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event OsmoticPoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

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
        address _initOsmoticPoolImplementation,
        address _projectRegistry,
        IStakingFactory _stakingFactory
    ) {
        _disableInitializers();

        beacon = new UpgradeableBeacon(_initOsmoticPoolImplementation);

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

    // TODO: evaluate if is possible to have this logic here beacuse of ownership
    // otherwise the deployer does the beacon upgrades manually
    // function updateOsmoticPool(address _newImplementation) external onlyOwner {
    //     beacon.upgradeTo(_newImplementation);
    // }

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

    function lockBalance(address _token, uint256 _amount) public whenNotPaused {
        IStaking staking = stakingFactory.getOrCreateInstance(_token);

        _lockBalance(staking, msg.sender, _amount);
    }

    function unlockBalance(address _token, uint256 _amount) public whenNotPaused {
        IStaking staking = stakingFactory.getInstance(_token);

        _unlockBalance(staking, msg.sender, _amount);
    }

    /* *************************************************************************************************************************************/
    /* ** Locking and Supporting Functions                                                                                               ***/
    /* *************************************************************************************************************************************/

    function lockAndSupport(
        OsmoticPool _pool,
        uint256 _lockedAmount,
        ParticipantSupportUpdate[] calldata _participantUpdates
    ) external whenNotPaused {
        lockBalance(address(_pool.governanceToken()), _lockedAmount);

        _pool.updateProjectSupports(_participantUpdates);
    }

    function unsupportAndUnlock(
        OsmoticPool _pool,
        uint256 _unlockedAmount,
        ParticipantSupportUpdate[] calldata _participantUpdates
    ) external whenNotPaused {
        _pool.updateProjectSupports(_participantUpdates);

        unlockBalance(address(_pool.governanceToken()), _unlockedAmount);
    }

    /* *************************************************************************************************************************************/
    /* ** Participant Supported Pools Functions                                                                                          ***/
    /* *************************************************************************************************************************************/

    function increaseParticipantSupportedPools(address _participant, address _pool)
        external
        whenNotPaused
        onlyPool(_pool)
    {
        participantSupportedPools[_participant]++;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
    }

    function decreaseParticipantSupportedPools(address _participant, address _pool)
        external
        whenNotPaused
        onlyPool(_pool)
    {
        participantSupportedPools[_participant]--;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    /**
     * @dev ILockManager conformance.
     *      The Staking contract checks this on each request to unlock an amount managed by this Controller.
     *      Check the participant amount of supported pools and disable owners from unlocking their funds
     *      arbitrarily, as we want to control the release of the locked amount  when there is no remaining
     *      supported pools.
     * @return Whether the request to unlock tokens of a given owner should be allowed
     */
    function canUnlock(address _user, uint256) external view returns (bool) {
        return participantSupportedPools[_user] == 0;
    }

    function getParticipantStaking(address _participant, address _token) public view returns (uint256) {
        return stakingFactory.getInstance(_token).lockedBalanceOf(_participant);
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
