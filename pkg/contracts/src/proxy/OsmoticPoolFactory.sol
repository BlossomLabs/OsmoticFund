// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {OsmoticPool} from "../OsmoticPool.sol";
import {OsmoticPoolBeacon} from "./OsmoticPoolBeacon.sol";

contract OsmoticPoolFactory {
    OsmoticPoolBeacon immutable beacon;

    constructor(OsmoticPoolBeacon _beacon) {
        beacon = _beacon;
    }

    function createOsmoticPool(bytes calldata _initCall) external returns (address) {
        BeaconProxy pool = new BeaconProxy(address(beacon), _initCall);

        return address(pool);
    }
}
