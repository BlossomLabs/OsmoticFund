// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

contract OsmoticControllerPause is Setup {
    function test_Pause() public {
        controller.pause();
        assertTrue(controller.paused());
    }

    function test_Unpause() public {
        controller.pause();
        controller.unpause();
        assertTrue(!controller.paused());
    }

    function test_RevertWhen_PausingAsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        controller.pause();
    }

    function test_RevertWhen_UnpausingAsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        controller.unpause();
    }
}
