// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OsmoticFormula} from "./OsmoticFormula.sol";

contract OsmoticPool is Initializable, OwnableUpgradeable, UUPSUpgradeable, OsmoticFormula {
    uint256 public immutable version;

    struct Flow {
        uint256 lastRate;
        uint256 lastTime;
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 version_) {
        version = version_;
        _disableInitializers();
    }

    function initialize(uint256 _decay, uint256 _drop, uint256 _maxFlow, uint256 _minStakeRatio) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __OsmoticFormula_init(_decay, _drop, _maxFlow, _minStakeRatio);
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setPoolSettings(uint256 _decay, uint256 _drop, uint256 _maxFlow, uint256 _minStakeRatio)
        public
        onlyOwner
    {
        _setOsmoticParams(_decay, _drop, _maxFlow, _minStakeRatio);
    }
}
