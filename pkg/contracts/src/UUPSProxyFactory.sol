// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1967Proxy} from "@oz/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxyFactory {
    function deploy(address implementation, bytes memory initCall) external returns (address proxyAddress) {
        bytes memory proxyCode = _getDeployProxyCode(implementation, initCall);

        proxyAddress = _deployCode(proxyCode);
    }

    function _getDeployProxyCode(address _implementation, bytes memory _initCall)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_implementation, _initCall));
    }

    function _deployCode(bytes memory code) internal returns (address addr) {
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }
    }
}
