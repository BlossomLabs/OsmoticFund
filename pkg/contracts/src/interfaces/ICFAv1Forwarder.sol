// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICFAv1Forwarder {
    function createFlow(address token, address receiver, int96 flowRate, bytes calldata ctx)
        external
        returns (bytes memory newCtx);

    function updateFlow(address token, address receiver, int96 flowRate, bytes calldata ctx)
        external
        returns (bytes memory newCtx);

    function deleteFlow(address token, address sender, address receiver, bytes calldata ctx)
        external
        returns (bytes memory newCtx);
}
