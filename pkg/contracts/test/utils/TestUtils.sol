// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticFormulaUtils} from "./OsmoticFormulaUtils.sol";
import {ProjectUtils} from "./ProjectUtils.sol";
import {ProxyUtils} from "./ProxyUtils.sol";

abstract contract TestUtils is OsmoticFormulaUtils, ProjectUtils, ProxyUtils {}
