// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "@oz/utils/Address.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

import {IStakingFactory} from "./interfaces/IStakingFactory.sol";
import {ILockManager} from "./interfaces/ILockManager.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {OsmoticPool} from "./OsmoticPool.sol";

error ErrorAddressNotContract(address _address);
error ErrorNotOsmoticPool();

contract OsmoticController is ILockManager, Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public immutable version;

    struct PoolDelegate {
        address ownedPool;
        bool isPoolDelegate;
    }

    IStakingFactory public stakingFactory; // Staking factory, for finding each collateral token's staking pool

    mapping(address => bool) public isPool;
    mapping(address => bool) public isPoolDeployer;

    mapping(address => uint256) internal participantSupportedPools; // Amount of pools supported by a participant

    mapping(bytes32 => mapping(address => bool)) public isFactory;

    mapping(address => PoolDelegate) public poolDelegates;

    event ValidFactorySet(bytes32 indexed factoryKey_, address indexed factory_, bool indexed isValid_);
    event ValidPoolDeployerSet(address indexed poolDeployer_, bool indexed isValid_);
    event ValidPoolDelegateSet(address indexed account_, bool indexed isValid_);
    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    /**
     *  @dev   The ownership of the pool manager was transferred.
     *  @param fromPoolDelegate_ The address of the previous pool delegate.
     *  @param toPoolDelegate_   The address of the new pool delegate.
     *  @param poolManager_      The address of the pool manager.
     */
    event PoolManagerOwnershipTransferred(
        address indexed fromPoolDelegate_, address indexed toPoolDelegate_, address indexed poolManager_
    );

    modifier onlyPool() {
        if (!isPool[msg.sender]) {
            revert ErrorNotOsmoticPool();
        }

        _;
    }

    constructor(uint256 _version, IStakingFactory _stakingFactory) {
        _disableInitializers();

        if (!Address.isContract(address(_stakingFactory))) {
            revert ErrorAddressNotContract(address(_stakingFactory));
        }

        version = _version;
        stakingFactory = _stakingFactory;
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     *
     */
    /**
     * Allowlist Setters                                                                                                              **
     */
    /**
     *
     */

    function setValidFactory(bytes32 factoryKey_, address factory_, bool isValid_) external onlyOwner {
        isFactory[factoryKey_][factory_] = isValid_;
        emit ValidFactorySet(factoryKey_, factory_, isValid_);
    }

    function setValidPoolDelegate(address account_, bool isValid_) external onlyOwner {
        require(account_ != address(0), "OC:SVPD:ZERO_ADDRESS");

        // Cannot remove pool delegates that own a pool manager.
        require(isValid_ || poolDelegates[account_].ownedPool == address(0), "OC:SVPD:OWNS_POOL_MANAGER");

        poolDelegates[account_].isPoolDelegate = isValid_;
        emit ValidPoolDelegateSet(account_, isValid_);
    }

    function setValidPoolDeployer(address poolDeployer_, bool isValid_) public onlyOwner {
        isPoolDeployer[poolDeployer_] = isValid_;
        emit ValidPoolDeployerSet(poolDeployer_, isValid_);
    }

    /**
     *
     */
    /**
     * Contract Control Functions                                                                                                     **
     */
    /**
     *
     */
    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external {
        PoolDelegate storage fromDelegate_ = poolDelegates[fromPoolDelegate_];
        PoolDelegate storage toDelegate_ = poolDelegates[toPoolDelegate_];

        require(fromDelegate_.ownedPool == msg.sender, "OC:TOPM:NOT_AUTHORIZED");
        require(toDelegate_.isPoolDelegate, "OC:TOPM:NOT_POOL_DELEGATE");
        require(toDelegate_.ownedPool == address(0), "OC:TOPM:ALREADY_OWNS");

        fromDelegate_.ownedPool = address(0);
        toDelegate_.ownedPool = msg.sender;

        emit PoolManagerOwnershipTransferred(fromPoolDelegate_, toPoolDelegate_, msg.sender);
    }

    /**
     * @dev ILockManager conformance.
     *      The Staking contract checks this on each request to unlock an amount managed by this Agreement.
     *      It always returns false to disable owners from unlocking their funds arbitrarily, as we
     *      want to control the release of the locked amount when actions are closed or settled.
     * @return Whether the request to unlock tokens of a given owner should be allowed
     */

    function canUnlock(address _user, uint256) external view returns (bool) {
        return participantSupportedPools[_user] == 0;
    }

    function lockBalance(address _token, uint256 _amount) public {
        IStaking staking = IStaking(stakingFactory.getOrCreateInstance(_token));

        _lockBalance(staking, msg.sender, _amount);
    }

    function unlockBalance(address _token, uint256 _amount) public {
        IStaking staking = IStaking(stakingFactory.getInstance(_token));

        _unlockBalance(staking, msg.sender, _amount);
    }

    // TODO: wrap into a tuple both _projectIds and _supportDeltas
    function lockAndSupport(
        OsmoticPool _pool,
        uint256 _lockedAmount,
        uint256[] calldata _projectIds,
        int256[] calldata _supportDeltas
    ) external {
        lockBalance(address(_pool.governanceToken()), _lockedAmount);

        _pool.changeProjectSupports(_projectIds, _supportDeltas);
    }

    function unsupportAndUnlock(
        OsmoticPool _pool,
        uint256 _unlockedAmount,
        uint256[] calldata _projectIds,
        int256[] calldata _supportDeltas
    ) external {
        _pool.changeProjectSupports(_projectIds, _supportDeltas);

        unlockBalance(address(_pool.governanceToken()), _unlockedAmount);
    }

    function increaseParticipantSupportedPools(address _participant) external onlyPool {
        participantSupportedPools[_participant]++;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
    }

    function decreaseParticipantSupportedPools(address _participant) external onlyPool {
        participantSupportedPools[_participant]--;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
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

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_) {
        isPoolDelegate_ = poolDelegates[account_].isPoolDelegate;
    }

    function getParticipantStaking(address _participant, address _token) public view returns (uint256) {
        return IStaking(stakingFactory.getInstance(_token)).lockedBalanceOf(_participant);
    }

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
