// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {UpgradeScripts} from "upgrade-scripts/UpgradeScripts.sol";
import {ERC1967Proxy} from "@oz/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@oz/proxy/utils/UUPSUpgradeable.sol";

contract SetupScript is UpgradeScripts {
    /// @dev using OZ's ERC1967Proxy
    function getDeployProxyCode(address _implementation, bytes memory _initCall)
        internal
        pure
        override
        returns (bytes memory)
    {
        return abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_implementation, _initCall));
    }

    /// @dev using OZ's UUPSUpgradeable function call
    function upgradeProxy(address _proxy, address _newImplementation) internal override {
        UUPSUpgradeable(_proxy).upgradeTo(_newImplementation);
    }

    // /// @dev override using forge's built-in create2 deployer (only works for specific chains, or: use your own!)
    // function deployCode(bytes memory code) internal override returns (address addr) {
    //     uint256 salt = 0x1234;

    //     assembly {
    //         addr := create2(0, add(code, 0x20), mload(code), salt)
    //     }
    // }
}
