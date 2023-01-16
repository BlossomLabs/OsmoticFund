// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OsmoticFormula, OsmoticParams} from "./OsmoticFormula.sol";
import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";

contract OsmoticPool is Initializable, OwnableUpgradeable, UUPSUpgradeable, OsmoticFormula {
    uint256 public immutable version;
    ICFAv1Forwarder public immutable cfaForwarder;

    uint8 MAX_ACTIVE_PROJECTS = 15;

    address public fundingToken;
    address public governanceToken;

    OsmoticParams public osmoticParams;

    struct Project {
        uint256 totalSupport;
        bool active;
        address beneficiary;
        uint256 flowLastRate;
        uint256 flowLastTime;
        bytes32 projectId;
        mapping(address => uint256) participantSupports;
        address submitter;
    }

    // projectId => project
    mapping(bytes32 => Project) public projects;
    mapping(address => uint256) internal totalParticipantSupport;
    bytes32[MAX_ACTIVE_PROJECTS] internal activeProjects;

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 _version, ICFAv1Forwarder _cfaForwarder) {
        version = _version;
        cfaForwarder = _cfaForwarder;
        _disableInitializers();
    }

    function initialize(OsmoticParams _params) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __OsmoticFormula_init(_params);
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setPoolSettings(OsmoticParams _params) public onlyOwner {
        _setOsmoticParams(_params);
    }

    function registerProposals(uint256[] memory _proposalIds, address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            _registerProposal(_proposalIds[i], _addresses[i]);
        }
    }

    function registerProposal(uint256 _proposalId, address _beneficiary) public {
        require(_proposalId != 0);
        require(_beneficiary != address(0));
        require(!registeredBeneficiary[_beneficiary]);

        (uint256 amount,,,,,,, ProposalStatus status, address submmiter,) = cv.getProposal(_proposalId);

        if (status != ProposalStatus.Active) {
            revert ProposalOnlyActive();
        }

        if (amount != 0) {
            revert ProposalOnlySignaling();
        }

        if (msg.sender != submmiter) {
            revert ProposalOnlySubmmiter();
        }

        _registerProposal(_proposalId, _beneficiary);
    }
}
