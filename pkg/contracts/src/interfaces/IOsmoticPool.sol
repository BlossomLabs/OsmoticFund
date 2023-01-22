// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IOsmoticProxied} from "./IOsmoticProxied.sol";

interface IOsmoticPool is IOsmoticProxied {
    /**
     *  @dev    Gets the address of the controller.
     *  @return controller_ The address of the controller.
     */
    function controller() external view returns (address controller_);

    /**
     *  @dev    Gets the address of the owner.
     *  @return owner_ The address of the owner.
     */
    function owner() external view returns (address owner_);
}
