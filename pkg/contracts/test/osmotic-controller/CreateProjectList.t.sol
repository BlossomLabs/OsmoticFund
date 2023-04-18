// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {MimeToken} from "mime-token/MimeTokenFactory.sol";

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";
import {OwnableProjectList} from "../../src/projects/OwnableProjectList.sol";

// TODO: refactor after abstracting out logic into factory
contract OsmoticControllerCreateProjectList is Setup {
    // TODO: find a better way to get the address of the next contract in Solidity
    address constant NEXT_PROJECT_LIST = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;

    event MimeTokenCreated(address token);
    event ProjectListCreated(address indexed list);
    event OsmoticPoolCreated(address indexed pool);

    function test_CreateProjectList() public {
        vm.expectEmit(true, true, true, true);
        emit ProjectListCreated(NEXT_PROJECT_LIST);

        vm.prank(owner);
        address projectListAddress = controller.createProjectList("My project list");
        OwnableProjectList projectList = OwnableProjectList(projectListAddress);

        assertEq(projectList.name(), "My project list", "new list's name mismatch");
        assertTrue(controller.isList(projectListAddress), "list is not registered");
        assertEq(OwnableProjectList(projectListAddress).owner(), owner, "new list's owner mismatch");
    }

    function test_RevertWhen_CallingWithPausedController() public {
        controller.pause();

        vm.expectRevert("Pausable: paused");

        controller.createProjectList("New list");
    }
}
