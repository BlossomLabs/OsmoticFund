// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

interface ICFAv1Forwarder {
    function setFlowrate(IERC20 token, address receiver, int96 flowrate) external returns (bool);

    function getFlowrate(IERC20 token, address sender, address receiver) external view returns (int96 flowrate);
}
