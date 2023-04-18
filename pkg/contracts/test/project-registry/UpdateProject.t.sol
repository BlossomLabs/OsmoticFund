// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ProjectRegistrySetup} from "../setups/ProjectRegistrySetup.sol";

import {Project} from "../../src/interfaces/IProjectList.sol";
import {BeneficiaryAlreadyExists, UnauthorizedProjectAdmin} from "../../src/projects/ProjectRegistry.sol";

contract ProjectRegistryUpdateProject is ProjectRegistrySetup {
    address notAuthorized = makeAddr("notAuthorized");
    address newAdmin = makeAddr("newAdmin");
    address newBeneficiary = makeAddr("newBeneficiary");
    bytes newContenthash = bytes("QmcJNTXjdRyeixbpFwd8cmd1XffszD2kiUcCogaiucmtDk");

    uint256 registeredProjectId;

    event ProjectUpdated(uint256 indexed projectId, address admin, address beneficiary, bytes contenthash);

    function setUp() public override {
        super.setUp();

        vm.prank(projectAdmin);
        registeredProjectId = projectRegistry.registerProject(projectBeneficiary, DEFAULT_CONTENT_HASH);
    }

    function test_UpdateRegistry() public {
        vm.expectEmit(true, true, true, true);
        emit ProjectUpdated(registeredProjectId, newAdmin, newBeneficiary, newContenthash);

        vm.prank(projectAdmin);

        projectRegistry.updateProject(registeredProjectId, newAdmin, newBeneficiary, newContenthash);

        Project memory project = projectRegistry.getProject(registeredProjectId);

        assertEq(project.admin, newAdmin, "admin mismatch");
        assertEq(project.beneficiary, newBeneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, newContenthash, "contenthash mismatch");
    }

    function test_RevertWhen_UpdatingProjectWithNotAdmin() public {
        vm.expectRevert(UnauthorizedProjectAdmin.selector);

        vm.prank(notAuthorized);
        projectRegistry.updateProject(registeredProjectId, notAuthorized, newBeneficiary, newContenthash);
    }

    function test_RevertWhen_UpdatingProjectWithNoBeneficiary() public {
        vm.expectRevert("ProjectRegistry: beneficiary cannot be zero address");
        vm.prank(projectAdmin);
        projectRegistry.updateProject(registeredProjectId, projectAdmin, address(0), DEFAULT_CONTENT_HASH);
    }

    function test_RevertWhen_UpdatingProjectWithExistingBeneficiary() public {
        address otherAdmin = makeAddr("otherAdmin");
        address otherBeneficiary = makeAddr("otherBeneficiary");

        vm.prank(otherAdmin);
        uint256 projectId = projectRegistry.registerProject(otherBeneficiary, newContenthash);

        vm.prank(projectAdmin);

        vm.expectRevert(abi.encodeWithSelector(BeneficiaryAlreadyExists.selector, otherBeneficiary));
        projectRegistry.updateProject(registeredProjectId, projectAdmin, otherBeneficiary, newContenthash);
    }
}
