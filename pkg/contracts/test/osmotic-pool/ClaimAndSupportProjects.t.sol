// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {MimeToken} from "mime-token/MimeToken.sol";

import {OsmoticPoolSetup} from "../setups/OsmoticPoolSetup.sol";

import {ProjectSupport} from "../../src/OsmoticPool.sol";

contract OsmoticPoolClaimAndSupportProjects is OsmoticPoolSetup {
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);

    function test_ClaimAndSupportProjects() public {
        uint256 projectId = _createProject();
        ProjectSupport[] memory projectSupports = new ProjectSupport[](1);
        uint256 claimedAmount = UNCLAIMED_AMOUNT;
        projectSupports[0].projectId = projectId;
        projectSupports[0].deltaSupport = int256(UNCLAIMED_AMOUNT);

        uint256 holderBalanceBefore = mimeToken.balanceOf(UNCLAIMED_MIME_HOLDER3);
        uint256 projectSupportBefore = pool.getProjectSupport(projectId);
        uint256 participantSupportBefore = pool.getParticipantSupport(projectId, UNCLAIMED_MIME_HOLDER3);

        vm.expectCall(
            address(mimeToken),
            abi.encodeWithSelector(
                MimeToken.claim.selector, 3, UNCLAIMED_MIME_HOLDER3, claimedAmount, HOLDERS_PROOFS[3]
            )
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectSupportUpdated(CURRENT_ROUND, projectId, UNCLAIMED_MIME_HOLDER3, projectSupports[0].deltaSupport);

        vm.prank(UNCLAIMED_MIME_HOLDER3);
        pool.claimAndSupportProjects(3, UNCLAIMED_MIME_HOLDER3, claimedAmount, HOLDERS_PROOFS[3], projectSupports);

        uint256 holderBalanceAfter = mimeToken.balanceOf(UNCLAIMED_MIME_HOLDER3);
        uint256 projectSupportAfter = pool.getProjectSupport(projectId);
        uint256 participantSupportAfter = pool.getParticipantSupport(projectId, UNCLAIMED_MIME_HOLDER3);

        assertEq(holderBalanceAfter, holderBalanceBefore + UNCLAIMED_AMOUNT, "Mime holder balance mismatch");
        assertEq(projectSupportAfter, projectSupportBefore + claimedAmount, "Project support mismatch");
        assertEq(
            participantSupportAfter, participantSupportBefore + claimedAmount, "Project participant support mismatch"
        );
    }
}
