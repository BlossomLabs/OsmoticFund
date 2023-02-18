// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {BeneficiaryAlreadyExists, UnauthorizedProjectAdmin} from "../src/projects/ProjectRegistry.sol";

import {Project} from "../src/interfaces/IProjectList.sol";

import {BaseSetup} from "./BaseSetup.sol";

contract ProjectRegistryTest is Test, BaseSetup {
    address beneficiary = address(1);
    address projectAdmin = address(3);

    bytes contenthash = bytes("QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm");

    event ProjectAdminChanged(uint256 indexed projectId, address newAdmin);
    event ProjectUpdated(uint256 indexed projectId, address admin, address beneficiary, bytes contenthash);

    function setUp() public override {
        super.setUp();

        vm.label(beneficiary, "beneficiary");
        vm.label(projectAdmin, "projectAdmin");
    }

    function testFuzzRegisterProject(address _beneficiary, bytes calldata _contenthash) public {
        vm.assume(_beneficiary != address(0));

        vm.expectEmit(true, false, false, true);
        emit ProjectUpdated(1, projectAdmin, _beneficiary, _contenthash);

        vm.prank(projectAdmin);
        uint256 projectId = registry.registrerProject(_beneficiary, _contenthash);

        Project memory project = registry.getProject(projectId);

        assertEq(registry.nextProjectId(), 2, "projectId did not increase");
        assertEq(project.admin, projectAdmin, "admin mismatch");
        assertEq(project.beneficiary, _beneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, _contenthash, "contenthash mismatch");
    }

    function testFailWhenRegisteringProjectWithNoBeneficiary() public {
        registry.registrerProject(address(0), contenthash);
    }

    function testWhenRegisteringProjectWithExistingBeneficiary() public {
        registry.registrerProject(beneficiary, contenthash);

        vm.expectRevert(abi.encodeWithSelector(BeneficiaryAlreadyExists.selector, beneficiary));

        registry.registrerProject(beneficiary, contenthash);
    }

    function testFuzzUpdateRegistry(address newBeneficiary, address newAdmin, bytes calldata newContenthash) public {
        vm.assume(newBeneficiary != address(0));
        vm.assume(newAdmin != address(0));

        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        vm.expectEmit(true, false, false, true);
        emit ProjectUpdated(1, newAdmin, newBeneficiary, newContenthash);

        registry.updateProject(projectId, newAdmin, newBeneficiary, newContenthash);

        Project memory project = registry.getProject(projectId);

        assertEq(registry.nextProjectId(), 2, "projectId did not increase");
        assertEq(project.admin, newAdmin, "admin mismatch");
        assertEq(project.beneficiary, newBeneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, newContenthash, "contenthash mismatch");
    }

    function testWhenUpdatingProjectWithNotAdmin() public {
        vm.prank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        vm.expectRevert(UnauthorizedProjectAdmin.selector);

        vm.prank(notAuthorized);
        registry.updateProject(projectId, notAuthorized, beneficiary, contenthash);
    }

    function testFailWhenUpdatingProjectWithNoBeneficiary() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        registry.updateProject(projectId, projectAdmin, address(0), contenthash);
    }

    function testWhenUpdatingProjectWithExistingBeneficiary() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        vm.expectRevert(abi.encodeWithSelector(BeneficiaryAlreadyExists.selector, beneficiary));

        registry.updateProject(projectId, projectAdmin, beneficiary, contenthash);
    }

    function testProjectExist() public {
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        assertEq(registry.projectExists(projectId), true, "project does not exist");
    }
}
