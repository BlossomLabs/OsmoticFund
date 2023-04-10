// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {StdCheats} from "forge-std/StdCheats.sol";

import "@oz/utils/Strings.sol";

import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";

abstract contract ProjectUtils is StdCheats {
    bytes constant DEFAULT_CONTENT_HASH = bytes("QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm");

    function createBeneficiaryAddress(uint256 projectId) public returns (address) {
        string memory projectIdStr = Strings.toString(projectId);

        return makeAddr(string.concat("beneficiary", projectIdStr));
    }

    function createProjectInRegistry(ProjectRegistry _projectRegistry) public returns (uint256 projectId) {
        address beneficiary = createBeneficiaryAddress(_projectRegistry.nextProjectId());

        return _projectRegistry.registerProject(beneficiary, DEFAULT_CONTENT_HASH);
    }
}
