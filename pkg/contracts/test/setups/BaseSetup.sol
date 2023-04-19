// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";
import {MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";
import {MimeToken} from "mime-token/MimeToken.sol";

import {TestUtils} from "../utils/TestUtils.sol";

import {SetupScript} from "../../src/SetupScript.sol";
import {ICFAv1Forwarder} from "../../src/interfaces/ICFAv1Forwarder.sol";
import {ISuperToken} from "../../src/interfaces/ISuperToken.sol";
import {OsmoticParams} from "../../src/OsmoticFormula.sol";

abstract contract BaseSetup is SetupScript, Test, TestUtils {
    uint256 VERSION = 1;

    // fork env
    uint256 GOERLI_FORK_BLOCK_NUMBER = 8689679; // Mime token factory deployment block
    string GOERLI_RPC_URL = vm.envOr("GOERLI_RPC_URL", string("https://rpc.ankr.com/eth_goerli"));

    // Goerli test deps
    address constant CFA_V1_FORWARDER_ADDRESS = 0xcfA132E353cB4E398080B9700609bb008eceB125;
    address constant FUNDING_TOKEN_ADDRESS = 0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00; // DAIx
    address constant MIME_TOKEN_FACTORY_ADDRESS = 0x3D1Bebcfc55192bF6eE9E94F0EBA2fb54D5423aC;

    ICFAv1Forwarder constant CFA_FORWARDER = ICFAv1Forwarder(CFA_V1_FORWARDER_ADDRESS);
    ISuperToken constant FUNDING_TOKEN = ISuperToken(FUNDING_TOKEN_ADDRESS);
    MimeTokenFactory constant MIME_TOKEN_FACTORY = MimeTokenFactory(MIME_TOKEN_FACTORY_ADDRESS);

    // Mime token init data
    address constant MIME_HOLDER0 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant MIME_HOLDER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant UNCLAIMED_MIME_HOLDER3 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // TODO: Abstract out all mime related logic into a separate file on the MimeToken repo
    bytes32[][4] HOLDERS_PROOFS = [
        [
            bytes32(0x11079118024000df209172a1af6eb7a9ea4e5b2bd6e2760481566ce6bee3e0cd),
            bytes32(0xf46478da86f39b5d4f0af753bbc54ab402404b5ed5369f359e8fb24268b12edc)
        ],
        [bytes32(0x0), bytes32(0x0)],
        [
            bytes32(0x9224c4ad0c0d0ea48b770992025547eff95b06645c92f0c047c9d7c161de8091),
            bytes32(0x0627178dd800c957efbe02c61cf32bcab724b4e87b735d34f03e6766ca038c10)
        ],
        [
            bytes32(0x2da52479032a949acaa5138ddd9cf15898df48085ce832cb5fad7367f7bd3cac),
            bytes32(0x0627178dd800c957efbe02c61cf32bcab724b4e87b735d34f03e6766ca038c10)
        ]
    ];
    bytes32 constant MERKLE_ROOT = 0x47c52ef48ec180964d648c3783e0b02202f16211392b986fbe2627f021657f2b; // init with: https://gist.github.com/0xGabi/4ca04edae9753ec32ffed7dc0cffe31e
    uint256 constant ROUND_DURATION = 2 weeks;
    uint256 constant CURRENT_ROUND = 0;
    uint256 constant UNCLAIMED_AMOUNT = 0x3635c9adc5dea00000;

    OsmoticParams OSMOTIC_PARAMS = OsmoticParams({
        decay: 999999197747000000, // 10 days (864000 seconds) to reach 50% of targetRate
        drop: 2,
        maxFlow: 19290123456, // 5% of Common Pool per month = Math.floor(0.05e18 / (30 * 24 * 60 * 60))
        minStakeRatio: 25000000000000000 // 2.5% of Total Support = the minimum stake to start receiving funds
    });

    function setUpUpgradeScripts() internal override {
        UPGRADE_SCRIPTS_BYPASS = true; // deploys contracts without any checks whatsoever
    }

    function setUp() public virtual {
        // if in fork mode create and select fork
        vm.createSelectFork(GOERLI_RPC_URL, GOERLI_FORK_BLOCK_NUMBER);

        vm.label(CFA_V1_FORWARDER_ADDRESS, "cfaForwarder");
        vm.label(FUNDING_TOKEN_ADDRESS, "fundingToken");
        vm.label(MIME_TOKEN_FACTORY_ADDRESS, "mimeTokenFactory");

        vm.label(MIME_HOLDER0, "mimeHolder0");
        vm.label(MIME_HOLDER2, "mimeHolder2");
        vm.label(UNCLAIMED_MIME_HOLDER3, "unclaimedMimeHolder3");
    }

    function _claimMimeTokens(MimeToken _mimeToken) internal {
        _mimeToken.claim(0, MIME_HOLDER0, UNCLAIMED_AMOUNT, HOLDERS_PROOFS[0]);
        _mimeToken.claim(2, MIME_HOLDER2, UNCLAIMED_AMOUNT, HOLDERS_PROOFS[2]);
    }
}
