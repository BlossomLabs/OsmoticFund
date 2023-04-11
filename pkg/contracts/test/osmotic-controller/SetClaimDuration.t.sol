// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";

contract OsmoticControllerSetClaimDuration is Setup {
    function test_SetClaimDuration() public {
        uint256 newDuration = 2 weeks;
        controller.setClaimDuration(newDuration);

        assertEq(controller.claimDuration(), newDuration, "claimDuration mismatch");
    }

    function test_RevertWhen_SetClaimDurationAsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(notOwner);
        controller.setClaimDuration(2 weeks);
    }
}
