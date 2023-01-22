// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IOsmoticProxyFactory, OsmoticProxyFactory} from "./OsmoticProxyFactory.sol";

import {IOsmoticPoolFactory} from "../interfaces/IOsmoticPoolFactory.sol";
import {IOsmoticController} from "../interfaces/IOsmoticController.sol";

contract OsmoticPoolFactory is IOsmoticPoolFactory, OsmoticProxyFactory {
    constructor(address controller_) OsmoticProxyFactory(controller_) {}

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        public
        override(IOsmoticProxyFactory, OsmoticProxyFactory)
        returns (address instance_)
    {
        require(IOsmoticController(controller).isPoolDeployer(msg.sender), "OPMF:CI:NOT_DEPLOYER");

        instance_ = super.createInstance(arguments_, salt_);
    }
}
