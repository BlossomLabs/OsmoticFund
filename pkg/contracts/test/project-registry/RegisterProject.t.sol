// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ProjectRegistrySetup} from "../setups/ProjectRegistrySetup.sol";

import {BeneficiaryAlreadyExists} from "../../src/projects/ProjectRegistry.sol";
import {Project} from "../../src/interfaces/IProjectList.sol";

contract ProjectRegistryRegisterProject is ProjectRegistrySetup {
    event ProjectUpdated(uint256 indexed projectId, address admin, address beneficiary, bytes contenthash);

    function test_RegisterProject() public {
        vm.expectEmit(true, false, false, true);
        emit ProjectUpdated(1, projectAdmin, projectBeneficiary, DEFAULT_CONTENT_HASH);

        vm.prank(projectAdmin);
        uint256 projectId = projectRegistry.registerProject(projectBeneficiary, DEFAULT_CONTENT_HASH);

        Project memory project = projectRegistry.getProject(projectId);

        assertEq(projectRegistry.nextProjectId(), 2, "projectId did not increase");
        assertEq(project.admin, projectAdmin, "admin mismatch");
        assertEq(project.beneficiary, projectBeneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, DEFAULT_CONTENT_HASH, "contenthash mismatch");
    }

    function test_RevertWhen_RegisteringProjectWithExistingBeneficiary() public {
        projectRegistry.registerProject(projectBeneficiary, DEFAULT_CONTENT_HASH);

        vm.expectRevert(abi.encodeWithSelector(BeneficiaryAlreadyExists.selector, projectBeneficiary));

        projectRegistry.registerProject(projectBeneficiary, DEFAULT_CONTENT_HASH);
    }

    function test_RevertWhen_RegisteringProjectWithhNoBeneficiary() public {
        vm.expectRevert("ProjectRegistry: beneficiary cannot be zero address");
        projectRegistry.registerProject(address(0), DEFAULT_CONTENT_HASH);
    }
}
