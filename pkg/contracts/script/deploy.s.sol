// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SetupConfig, SetupScript} from "../src/SetupScript.sol";

/* 
# Anvil Dry-Run (make sure it is running):
UPGRADE_SCRIPT_DRY_RUN=true forge script script/deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -vvvv --ffi

# Broadcast:
forge script script/deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -vvv --broadcast --ffi*/

contract deploy is SetupScript {
    SetupConfig public config;

    // goerli address
    address constant CFA_V1_FORWARDER_ADDRESS = 0xcfA132E353cB4E398080B9700609bb008eceB125;

    function setUp() public {
        config = SetupConfig({version: 1, roundDuration: 4 weeks, cfaV1Forwarder: CFA_V1_FORWARDER_ADDRESS});
    }

    function run() external {
        // uncommenting this line would mark the two contracts as having a compatible storage layout
        // isUpgradeSafe[31337][0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0][0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9] = true; // prettier-ignore

        // uncomment with current timestamp to confirm deployments on mainnet for 15 minutes or always allow via (block.timestamp)
        // mainnetConfirmation = 1667499028;

        // will run `vm.startBroadcast();` if ffi is enabled
        // ffi is required for running storage layout compatibility checks
        // if ffi is disabled, it will enter "dry-run" and
        // run `vm.startPrank(tx.origin)` instead for the script to be consistent
        upgradeScriptsBroadcast();

        // run the setup scripts
        setUpContracts(config);

        // we don't need broadcast from here on
        vm.stopBroadcast();

        // console.log and store these in `deployments/{chainid}/deploy-latest.json` (if not in dry-run)
        storeLatestDeployments();
    }
}
