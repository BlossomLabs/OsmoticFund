// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOsmoticController {
    function owner() external view returns (address);

    function paused() external view returns (bool);

    function isPoolDeployer(address) external view returns (bool);

    function transferOwnedPoolManager(address, address) external;

    function getParticipantStaking(address, address) external view returns (uint256);

    function decreaseParticipantSupportedPools(address) external;

    function increaseParticipantSupportedPools(address) external;
}
