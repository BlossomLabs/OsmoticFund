// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

abstract contract OsmoticSupport is Initializable {
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OsmoticFormula_init(uint256 _decay, uint256 _drop, uint256 _maxFlow, uint256 _minStakeRatio)
        internal
        onlyInitializing
    {
        _setOsmoticParams(_decay, _drop, _maxFlow, _minStakeRatio);
    }

    function setStake(uint256 _proposalId, uint256 _newAmount) external activeProposal(_proposalId) {
        uint256 currentAmount = getProposalVoterStake(_proposalId, msg.sender);
        if (_newAmount > currentAmount) {
            _stakeToProposal(_proposalId, _newAmount.sub(currentAmount), msg.sender);
        } else if (_newAmount < currentAmount) {
            _withdrawFromProposal(_proposalId, currentAmount.sub(_newAmount), msg.sender);
        }
    }

    function stakeToProposal(uint256 _proposalId, uint256 _amount) external activeProposal(_proposalId) {
        _stakeToProposal(_proposalId, _amount, msg.sender);
    }

    function withdrawFromProposal(uint256 _proposalId, uint256 _amount) external proposalExists(_proposalId) {
        _withdrawFromProposal(_proposalId, _amount, msg.sender);
    }

    /**
     * @notice Get stake of voter `_voter` on proposal #`_proposalId`
     * @param _proposalId Proposal id
     * @param _voter Voter address
     * @return Proposal voter stake
     */
    function getProposalVoterStake(uint256 _proposalId, address _voter) public view returns (uint256) {
        return proposals[_proposalId].voterStake[_voter];
    }

    /**
     * @notice Get the total stake of voter `_voter` on all proposals
     * @param _voter Voter address
     * @return Total voter stake
     */
    function getTotalVoterStake(address _voter) public view returns (uint256) {
        return totalVoterStake[_voter];
    }

    /**
     * @dev Calculate rate and store it on the proposal
     * @param _proposalId Proposal
     */
    function _saveCheckpoint(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.lastTime == block.timestamp) {
            return; // Rate already stored
        }
        // calculateRate and store it
        proposal.balance = claimable(_proposalId);
        proposal.lastRate = rate(_proposalId);
        proposal.lastTime = block.timestamp;
    }

    /**
     * @dev Support with an amount of tokens on a proposal
     * @param _proposalId Proposal id
     * @param _amount Amount of staked tokens
     * @param _from Account from which we stake
     */
    function _stakeToProposal(uint256 _proposalId, uint256 _amount, address _from) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(_amount > 0, "AMOUNT_CAN_NOT_BE_ZERO");

        uint256 unstakedAmount = stakeToken.balanceOf(_from).sub(totalVoterStake[_from]);
        if (_amount > unstakedAmount) {
            withdrawStake(_from, true);
        }

        require(totalVoterStake[_from].add(_amount) <= stakeToken.balanceOf(_from), "STAKING_MORE_THAN_AVAILABLE");

        if (proposal.lastTime == 0) {
            proposal.lastTime = block.timestamp;
        } else {
            _saveCheckpoint(_proposalId);
        }

        _updateVoterStakedProposals(_proposalId, _from, _amount, true);

        // _updateFundingFlow(proposal.beneficiary, calculateReward(proposal.lastRate));

        emit StakeAdded(
            _from, _proposalId, _amount, proposal.voterStake[_from], proposal.stakedTokens, proposal.lastRate
            );
    }

    /**
     * @dev Withdraw an amount of tokens from a proposal
     * @param _proposalId Proposal id
     * @param _amount Amount of withdrawn tokens
     * @param _from Account to withdraw from
     */
    function _withdrawFromProposal(uint256 _proposalId, uint256 _amount, address _from) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voterStake[_from] >= _amount, "WITHDRAW_MORE_THAN_STAKED");
        require(_amount > 0, "AMOUNT_CAN_NOT_BE_ZERO");

        if (proposal.active) {
            _saveCheckpoint(_proposalId);
        }

        _updateVoterStakedProposals(_proposalId, _from, _amount, false);

        emit StakeWithdrawn(
            _from, _proposalId, _amount, proposal.voterStake[_from], proposal.stakedTokens, proposal.lastRate
            );
    }

    /**
     * @dev Withdraw all staked tokens from proposals.
     * @param _voter Account to withdraw from.
     * @param _onlyCancelled If true withdraw only from cancelled proposals.
     */
    function withdrawStake(address _voter, bool _onlyCancelled) public {
        uint256 amount;
        uint256 i;
        uint256 len = voterStakedProposals[_voter].length();
        uint256[] memory voterStakedProposalsCopy = new uint256[](len);
        for (i = 0; i < len; i++) {
            voterStakedProposalsCopy[i] = voterStakedProposals[_voter].at(i);
        }
        for (i = 0; i < len; i++) {
            uint256 proposalId = voterStakedProposalsCopy[i];
            Proposal storage proposal = proposals[proposalId];
            if (!_onlyCancelled || !proposal.active) {
                // if _onlyCancelled = true, then do not withdraw from active proposals
                amount = proposal.voterStake[_voter];
                if (amount > 0) {
                    _withdrawFromProposal(proposalId, amount, _voter);
                }
            }
        }
    }

    function _updateVoterStakedProposals(uint256 _proposalId, address _from, uint256 _amount, bool _support) internal {
        Proposal storage proposal = proposals[_proposalId];
        EnumerableSet.UintSet storage voterStakedProposalsSet = voterStakedProposals[_from];

        if (_support) {
            stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
            proposal.stakedTokens = proposal.stakedTokens.add(_amount);
            proposal.voterStake[_from] = proposal.voterStake[_from].add(_amount);
            totalVoterStake[_from] = totalVoterStake[_from].add(_amount);
            totalStaked = totalStaked.add(_amount);

            if (!voterStakedProposalsSet.contains(_proposalId)) {
                require(voterStakedProposalsSet.length() < MAX_STAKED_PROPOSALS, "MAX_PROPOSALS_REACHED");
                voterStakedProposalsSet.add(_proposalId);
            }
        } else {
            stakeToken.safeTransfer(msg.sender, _amount);
            proposal.stakedTokens = proposal.stakedTokens.sub(_amount);
            proposal.voterStake[_from] = proposal.voterStake[_from].sub(_amount);
            totalVoterStake[_from] = totalVoterStake[_from].sub(_amount);
            totalStaked = totalStaked.sub(_amount);

            if (proposal.voterStake[_from] == 0) {
                voterStakedProposalsSet.remove(_proposalId);
            }
        }
    }
}
