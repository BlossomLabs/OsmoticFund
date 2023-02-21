// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {SetupScript} from "../script/SetupScript.sol";

import {ProjectRegistry} from "../src/projects/ProjectRegistry.sol";
import {
    OwnableProjectList,
    ProjectAlreadyInList,
    ProjectDoesNotExist,
    ProjectNotInList
} from "../src/projects/OwnableProjectList.sol";

import {Project} from "../src/interfaces/IProjectList.sol";

contract OwnableProjectListTest is Test, SetupScript {
    ProjectRegistry registry;
    OwnableProjectList ownedList;

    address deployer = address(this);

    // account
    address beneficiary1 = address(1);
    address beneficiary2 = address(2);
    address beneficiary3 = address(3);
    address notAuthorized = address(4);
    address projectAdmin = address(5);
    address listOwner = address(5);

    uint256 projectId1;
    uint256 projectId2;
    uint256 projectId3;
    uint256 projectIdNotInRegistry = 4;

    uint256[] projectIds;

    string listName = "listName";

    bytes cid = "QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm";
    bytes contenthash = bytes(cid);

    event ListUpdated(uint256 indexed projectId, bool included);

    function setUp() public {
        (address proxy,) =
            setUpContracts(abi.encode(uint256(1)), "ProjectRegistry", abi.encodeCall(ProjectRegistry.initialize, ()));

        registry = ProjectRegistry(proxy);

        vm.startPrank(projectAdmin);
        projectId1 = registry.registrerProject(beneficiary1, contenthash);
        projectId2 = registry.registrerProject(beneficiary2, contenthash);
        projectId3 = registry.registrerProject(beneficiary3, contenthash);
        vm.stopPrank();

        projectIds.push(projectId1);
        projectIds.push(projectId2);

        vm.prank(listOwner);
        ownedList = new OwnableProjectList(address(registry), listOwner, listName);

        vm.label(beneficiary1, "beneficiary1");
        vm.label(beneficiary2, "beneficiary2");
        vm.label(beneficiary3, "beneficiary3");
        vm.label(notAuthorized, "notAuthorized");
        vm.label(projectAdmin, "projectAdmin");
        vm.label(listOwner, "listOwner");
        vm.label(deployer, "deployer");
    }

    function testAddProject() public {
        vm.expectEmit(true, false, false, true);
        emit ListUpdated(1, true);

        vm.prank(listOwner);
        ownedList.addProject(projectId1);

        assertEq(ownedList.projectExists(projectId1), true, "project not included");
    }

    function testFailAddProjectNotAuthorized() public {
        vm.prank(notAuthorized);
        ownedList.addProject(projectId1);
    }

    function testAddProjectNotInRegistry() public {
        vm.expectRevert(abi.encodeWithSelector(ProjectDoesNotExist.selector, projectIdNotInRegistry));

        vm.prank(listOwner);
        ownedList.addProject(projectIdNotInRegistry);
    }

    function testAddProjectAlreadyInList() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.expectRevert(abi.encodeWithSelector(ProjectAlreadyInList.selector, projectId1));

        ownedList.addProject(projectId1);
    }

    function testRemoveProject() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.expectEmit(true, false, false, true);
        emit ListUpdated(1, false);

        ownedList.removeProject(projectId1);

        assertEq(ownedList.projectExists(projectId1), false, "project not removed");
    }

    function testFailRemoveProjectNotAuthorized() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.prank(notAuthorized);
        ownedList.removeProject(projectId1);
    }

    function testRemoveProjectNotInList() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, projectId2));

        ownedList.removeProject(projectId2);
    }

    function testRemoveProjectNotInRegistry() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.expectRevert(abi.encodeWithSelector(ProjectDoesNotExist.selector, projectIdNotInRegistry));

        ownedList.removeProject(projectIdNotInRegistry);
    }

    function testGetProject() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        Project memory project = ownedList.getProject(projectId1);

        assertEq(project.admin, projectAdmin, "admin mismatch");
        assertEq(project.beneficiary, beneficiary1, "beneficiary mismatch");
        assertEq(project.contenthash, contenthash, "contenthash mismatch");
    }

    function testGetProjectNotInList() public {
        vm.startPrank(listOwner);
        ownedList.addProject(projectId1);

        vm.expectRevert(abi.encodeWithSelector(ProjectNotInList.selector, projectId2));

        ownedList.getProject(projectId2);
    }

    function testAddProjects() public {
        vm.expectEmit(true, false, false, true);
        emit ListUpdated(1, true);
        vm.expectEmit(true, false, false, true);
        emit ListUpdated(2, true);

        vm.prank(listOwner);
        ownedList.addProjects(projectIds);

        assertEq(ownedList.projectExists(projectId1), true, "project1 not included");
        assertEq(ownedList.projectExists(projectId2), true, "project2 not included");
    }

    function testRemoveProjects() public {
        vm.startPrank(listOwner);
        ownedList.addProjects(projectIds);

        vm.expectEmit(true, false, false, true);
        emit ListUpdated(1, false);
        vm.expectEmit(true, false, false, true);
        emit ListUpdated(2, false);

        ownedList.removeProjects(projectIds);

        assertEq(ownedList.projectExists(projectId1), false, "project1 not removed");
        assertEq(ownedList.projectExists(projectId2), false, "project2 not removed");
    }
}
