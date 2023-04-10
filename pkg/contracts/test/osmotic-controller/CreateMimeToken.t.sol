// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {MimeToken, MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

import {OsmoticControllerSetup as Setup} from "../setups/OsmoticControllerSetup.sol";

contract OsmoticControllerCreateMimeToken is Setup {
    address constant NEXT_MIME_TOKEN = 0x807dB0d84DC300187C3c149AAeB2B044C9A3130E;
    string tokenName = "Mime Token";
    string tokenSymbol = "MIME";

    uint256 claimTimestamp;
    uint256 roundDuration;
    bytes initCall;

    function setUp() public override {
        super.setUp();

        claimTimestamp = controller.claimTimestamp();
        roundDuration = controller.claimDuration();

        initCall =
            abi.encodeCall(MimeToken.initialize, (tokenName, tokenSymbol, MERKLE_ROOT, claimTimestamp, roundDuration));
    }

    function test_CreateMimeToken() public {
        vm.expectCall(MIME_TOKEN_FACTORY_ADDRESS, abi.encodeCall(MimeTokenFactory.createMimeToken, (initCall)));

        vm.prank(owner);
        address mimeToken_ = controller.createMimeToken(initCall);
        MimeToken mimeToken = MimeToken(mimeToken_);

        assertEq(mimeToken.name(), tokenName, "token name mismatch");
        assertEq(mimeToken.symbol(), tokenSymbol, "token symbol mismatch");
        assertEq(mimeToken.decimals(), 18, "token decimals mismatch");
        assertEq(mimeToken.timestamp(), claimTimestamp, "token timestamp mismatch");
        assertEq(mimeToken.roundDuration(), roundDuration, "token duration mismatch");
        assertEq(mimeToken.owner(), owner, "token owner mismatch");
        assertTrue(controller.isToken(mimeToken_), "token is not registered");
    }

    function test_RevertWhen_CreatingTokenWithInvalidTimestamp() public {
        vm.expectRevert("OsmoticController: Invalid timestamp for token");
        bytes memory wrongInitCall =
            abi.encodeCall(MimeToken.initialize, (tokenName, tokenSymbol, MERKLE_ROOT, 9999, roundDuration));
        controller.createMimeToken(wrongInitCall);
    }

    function test_RevertWhen_CreatingTokenWithInvalidRoundDuration() public {
        vm.expectRevert("OsmoticController: Invalid round duration for token");
        bytes memory wrongInitCall =
            abi.encodeCall(MimeToken.initialize, (tokenName, tokenSymbol, MERKLE_ROOT, claimTimestamp, 9999));
        controller.createMimeToken(wrongInitCall);
    }
}
