// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";

contract ProjectRegistryConstructor is Test {
    function test_Constructor() public {
        uint256 version = 1;
        ProjectRegistry projectRegistry = new ProjectRegistry(version);

        assertEq(projectRegistry.version(), version);
    }
}
