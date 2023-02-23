// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {
    OwnableProjectList,
    ProjectAlreadyInList,
    ProjectDoesNotExist,
    ProjectNotInList
} from "../src/projects/OwnableProjectList.sol";

import {Project} from "../src/interfaces/IProjectList.sol";

import {BaseSetup} from "../script/BaseSetup.s.sol";

contract OwnableProjectListTest is Test, BaseSetup {
    OwnableProjectList ownedList;

    address beneficiary1 = address(1);
    address beneficiary2 = address(2);
    address listOwner = address(3);

    uint256 projectId1;
    uint256 projectId2;
    uint256 projectIdNotInRegistry = 3;

    uint256[] projectIds;

    string listName = "listName";
    bytes contenthash = bytes("QmWtGzMy7aNbMnLpmuNjKonoHc86mL1RyxqD2ghdQyq7Sm");

    event ListUpdated(uint256 indexed projectId, bool included);

    function setUp() public override {
        super.setUp();

        projectId1 = registry.registrerProject(beneficiary1, contenthash);
        projectId2 = registry.registrerProject(beneficiary2, contenthash);

        projectIds.push(projectId1);
        projectIds.push(projectId2);

        vm.prank(listOwner);
        ownedList = new OwnableProjectList(address(registry), listOwner, listName);

        vm.label(beneficiary1, "beneficiary1");
        vm.label(beneficiary2, "beneficiary2");
        vm.label(listOwner, "listOwner");
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

        assertEq(project.admin, deployer, "admin mismatch");
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
