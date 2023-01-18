// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

abstract contract StakingManager is Initializable {
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OsmoticFormula_init(uint256 _decay, uint256 _drop, uint256 _maxFlow, uint256 _minStakeRatio)
        internal
        onlyInitializing
    {
        _setOsmoticParams(_decay, _drop, _maxFlow, _minStakeRatio);
    }
}
