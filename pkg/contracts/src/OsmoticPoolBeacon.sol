// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

contract OsmoticPoolBeacon is Ownable {
    UpgradeableBeacon immutable beacon;

    constructor(address _initImplementation) Ownable() {
        beacon = new UpgradeableBeacon(_initImplementation);
    }

    function update(address _newImplementation) external onlyOwner {
        beacon.upgradeTo(_newImplementation);
    }

    function implementation() external view returns (address) {
        return beacon.implementation();
    }
}
