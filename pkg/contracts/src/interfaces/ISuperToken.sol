// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import "./ISuperfluidToken.sol";

interface ISuperToken is ISuperfluidToken, IERC20 {
    function selfMint(address account, uint256 amount, bytes calldata userData) external;

    function upgrade(uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256 balance);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getUnderlyingToken() external view returns (address tokenAddr);
}
