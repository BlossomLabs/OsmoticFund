// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import {UpgradeScripts} from "upgrade-scripts/UpgradeScripts.sol";

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

contract OsmoticControllerUpdateOsmoticPool is Setup {
// function test_UpdateOsmoticPoolImplementation() public {
//     address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));
//     UpgradeableBeacon(controller.beacon()).upgradeTo(newImplementation);

//     assertEq(controller.osmoticPoolImplementation(), newImplementation, "poolImplementation mismatch");
// }

// function test_RevertWhen_UpdatingWithNotOwner() public {
//     address newImplementation = setUpContract("OsmoticPool", abi.encode(address(12), address(13)));

//     vm.expectRevert("Ownable: caller is not the owner");

//     vm.prank(notAuthorized);
//     UpgradeableBeacon(controller.beacon()).upgradeTo(newImplementation);
// }
}
