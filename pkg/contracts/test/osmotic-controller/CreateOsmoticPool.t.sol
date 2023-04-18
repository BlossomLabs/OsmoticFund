// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {MimeToken} from "mime-token/MimeTokenFactory.sol";

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

import {OsmoticPool} from "../../src/OsmoticPool.sol";

// TODO: implement after abstracting out logic into factory
contract OsmoticControllerCreateOsmoticPool is Setup {}
