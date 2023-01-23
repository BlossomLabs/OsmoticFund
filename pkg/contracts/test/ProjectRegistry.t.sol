// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {SetupScript} from "../script/SetupScript.sol";

import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";

import {Project} from "../src/interfaces/IProjectList.sol";

contract ProjectRegistryTest is Test, SetupScript {
    ProjectRegistry registry;

    address deployer = address(this);

    // accounts
    address beneficiary = address(1);
    address notAuthorized = address(2);
    address projectAdmin = address(3);

    bytes cid = "QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm";
    bytes contenthash = bytes(cid);

    event ProjectAdminChanged(uint256 indexed projectId, address newAdmin);
    event ProjectUpdated(uint256 indexed projectId, address beneficiary, bytes contenthash);

    function setUp() public {
        (address proxy, address implementation) =
            setUpContracts(abi.encode(uint256(1)), "ProjectRegistry", abi.encodeCall(ProjectRegistry.initialize, ()));

        registry = ProjectRegistry(proxy);

        // labels
        vm.label(beneficiary, "beneficiary");
        vm.label(notAuthorized, "notAuthorizedAddress");
    }

    function testInitialize() public {
        // TODO: verify implementation is correct
        assertEq(registry.version(), 1, "version mismatch");
        assertEq(registry.nextProjectId(), 1, "nextProjectId mismatch");
        assertEq(registry.owner(), deployer, "owner mismatch");
    }

    function testRegisterProject() public {
        vm.expectEmit(true, false, false, true);
        emit ProjectUpdated(1, beneficiary, contenthash);

        vm.expectEmit(true, false, false, true);
        emit ProjectAdminChanged(1, projectAdmin);

        vm.prank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        Project memory project = registry.getProject(projectId);

        assertEq(registry.nextProjectId(), 2, "projectId did not increase");
        assertEq(project.admin, projectAdmin, "admin mismatch");
        assertEq(project.beneficiary, beneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, contenthash, "contenthash mismatch");
    }

    function testFailWhenRegisteringProjectWithNoBeneficiary() public {
        registry.registrerProject(address(0), contenthash);
    }

    function testFailWhenRegisteringProjectWithExistingBeneficiary() public {
        registry.registrerProject(beneficiary, contenthash);
        registry.registrerProject(beneficiary, contenthash);
    }

    function testUpdateRegistry() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        bytes memory newContenthash = bytes("QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm");
        address newBeneficiary = address(4);

        vm.expectEmit(true, false, false, true);
        emit ProjectUpdated(1, newBeneficiary, newContenthash);

        registry.updateProject(projectId, newBeneficiary, newContenthash);

        Project memory project = registry.getProject(projectId);

        assertEq(registry.nextProjectId(), 2, "projectId did not increase");
        assertEq(project.admin, projectAdmin, "admin mismatch");
        assertEq(project.beneficiary, newBeneficiary, "beneficiary mismatch");
        assertEq(project.contenthash, newContenthash, "contenthash mismatch");
    }

    function testFailWhenUpdatingProjectWithNotAdmin() public {
        vm.prank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        vm.prank(notAuthorized);
        registry.updateProject(projectId, beneficiary, contenthash);
    }

    function testFailWhenUpdatingProjectWithNoBeneficiary() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        registry.updateProject(projectId, address(0), contenthash);
    }

    function testFailWhenUpdatingProjectWithExistingBeneficiary() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        registry.updateProject(projectId, beneficiary, contenthash);
    }

    function testProjectExist() public {
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        assertEq(registry.projectExists(projectId), true, "project does not exist");
    }

    function testChangeProjectAdmin() public {
        vm.startPrank(projectAdmin);
        uint256 projectId = registry.registrerProject(beneficiary, contenthash);

        address newAdmin = address(5);

        vm.expectEmit(true, false, false, true);
        emit ProjectAdminChanged(projectId, newAdmin);

        registry.changeProjectAdmin(projectId, newAdmin);

        Project memory project = registry.getProject(projectId);

        assertEq(project.admin, newAdmin, "admin mismatch");
    }
}
