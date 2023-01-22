// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {ProxiedInternals} from "proxy-factory/ProxiedInternals.sol";

/// @title A Osmotic implementation that is to be proxied, will need OsmoticProxiedInternals.
abstract contract OsmoticProxiedInternals is ProxiedInternals {}
