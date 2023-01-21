// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
import {UUPSProxyFactory} from "./UUPSProxyFactory.sol";

error ErrorAddressNotContract(address _address);
error ErrorNotOsmoticPool();

contract OsmoticController is Initializable, OwnableUpgradeable, UUPSUpgradeable, ILockManager {
    using SafeERC20 for IERC20;

    uint256 public immutable version;

    UUPSProxyFactory public proxyFactory;
    IStakingFactory public stakingFactory; // Staking factory, for finding each collateral token's staking pool

    mapping(address => bool) isPool;

    mapping(address => uint256) internal participantSupportedPools; // Amount of pools supported by a participant

    event ParticipantSupportedPoolsChanged(address indexed participant, uint256 supportedPools);

    modifier onlyPool() {
        if (!isPool[msg.sender]) {
            revert ErrorNotOsmoticPool();
        }

        _;
    }

    constructor(uint256 _version, UUPSProxyFactory _proxyFactory, IStakingFactory _stakingFactory) {
        _disableInitializers();

        if (!Address.isContract(address(_proxyFactory))) {
            revert ErrorAddressNotContract(address(_proxyFactory));
        }

        if (!Address.isContract(address(_stakingFactory))) {
            revert ErrorAddressNotContract(address(_stakingFactory));
        }

        version = _version;
        proxyFactory = _proxyFactory;
        stakingFactory = _stakingFactory;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createPool(address _poolImplementation, bytes memory _poolInitPayload) external returns (address) {
        return proxyFactory.deploy(_poolImplementation, _poolInitPayload);
    }

    /**
     * @dev ILockManager conformance.
     *      The Staking contract checks this on each request to unlock an amount managed by this Agreement.
     *      It always returns false to disable owners from unlocking their funds arbitrarily, as we
     *      want to control the release of the locked amount when actions are closed or settled.
     * @return Whether the request to unlock tokens of a given owner should be allowed
     */

    function canUnlock(address, uint256) external pure returns (bool) {
        return false;
    }

    function lockBalance(address _token, uint256 _amount) public {
        IStaking staking = IStaking(stakingFactory.getOrCreateInstance(_token));

        _lockBalance(staking, msg.sender, _amount);
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

    function getParticipantStaking(address _participant, address _token) public view returns (uint256) {
        return IStaking(stakingFactory.getInstance(_token)).lockedBalanceOf(_participant);
    }

    function increaseParticipantSupportedPools(address _participant) external onlyPool {
        participantSupportedPools[_participant]++;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
    }

    function decreaseParticipantSupportedPools(address _participant) external onlyPool {
        participantSupportedPools[_participant]--;

        emit ParticipantSupportedPoolsChanged(_participant, participantSupportedPools[_participant]);
    }
}
