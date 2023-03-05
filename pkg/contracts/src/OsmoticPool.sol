// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IMimeToken} from "mime-token/interfaces/IMimeToken.sol";
import {ISuperToken} from "./interfaces/ISuperToken.sol";

import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";
import {IProjectList, Project, ProjectNotInList} from "./interfaces/IProjectList.sol";
import {OsmoticFormula, OsmoticParams} from "./OsmoticFormula.sol";
import {OsmoticController} from "./OsmoticController.sol";

error InvalidProjectList();
error InvalidGovernanceToken();
error SupportUnderflow();
error ProjectAlreadyActive(uint256 projectId);
error ProjectNeedsMoreStake(uint256 projectId, uint256 requiredStake, uint256 currentStake);

struct ProjectSupport {
    uint256 projectId;
    int256 deltaSupport;
}

contract OsmoticPool is Initializable, OwnableUpgradeable, OsmoticFormula {
    address public immutable cfaForwarder;
    address public immutable controller;

    uint8 constant MAX_ACTIVE_PROJECTS = 25;

    /* *************************************************************************************************************************************/
    /* ** Structs                                                                                                                        ***/
    /* *************************************************************************************************************************************/

    struct PoolProject {
        // round => project support
        mapping(uint256 => uint256) projectSupportAt;
        uint256 flowLastRate;
        uint256 flowLastTime;
        bool active;
        /**
         * We need to keep track of the beneficiary address in the pool because
         * can be updated in the ProjectRegistry
         */
        address beneficiary;
        // round => participant => support
        mapping(uint256 => mapping(address => uint256)) participantSupportAt;
    }

    address public projectList;
    address public fundingToken;
    address public governanceToken;

    OsmoticParams public osmoticParams;

    // projectId => PoolProject
    mapping(uint256 => PoolProject) public poolProjects;

    // round => total support
    mapping(uint256 => uint256) private totalSupportAt;
    // round => participant => total support
    mapping(uint256 => mapping(address => uint256)) private totalParticipantSupportAt;

    uint256[MAX_ACTIVE_PROJECTS] internal activeProjectIds;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(uint256 indexed round, uint256 indexed projectId, address participant, int256 delta);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);

    constructor(address _cfaForwarder, address _controller) {
        _disableInitializers();

        require((cfaForwarder = _cfaForwarder) != address(0), "Zero CFA Forwarder");
        require((controller = _controller) != address(0), "Zero Controller");
    }

    function initialize(
        address _fundingToken,
        address _governanceToken,
        address _projectList,
        OsmoticParams calldata _params
    ) public initializer {
        __Ownable_init();
        __OsmoticFormula_init(_params);

        require((fundingToken = _fundingToken) != address(0), "Zero Funding Token");

        if (OsmoticController(controller).isList(_projectList)) {
            projectList = _projectList;
        } else {
            revert InvalidProjectList();
        }

        if (OsmoticController(controller).isToken(_governanceToken)) {
            governanceToken = _governanceToken;
        } else {
            revert InvalidGovernanceToken();
        }
    }

    /* *************************************************************************************************************************************/
    /* ** Project Activation Function                                                                                                    ***/
    /* *************************************************************************************************************************************/

    function activateProject(uint256 _projectId) public {
        if (!IProjectList(projectList).projectExists(_projectId)) {
            revert ProjectNotInList(_projectId);
        }

        uint256 minSupport = projectSupport(_projectId);
        uint256 minIndex = _projectId;

        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                revert ProjectAlreadyActive(_projectId);
            }
            if (activeProjectIds[i] == 0) {
                // If position i is empty, use it
                minSupport = 0;
                minIndex = i;
                break;
            }
            if (projectSupport(activeProjectIds[i]) < minSupport) {
                minSupport = projectSupport(activeProjectIds[i]);
                minIndex = i;
            }
        }

        if (activeProjectIds[minIndex] == _projectId) {
            revert ProjectNeedsMoreStake(_projectId, minSupport, projectSupport(_projectId));
        }

        if (activeProjectIds[minIndex] == 0) {
            _activateProject(minIndex, _projectId);
            return;
        }

        _deactivateProject(minIndex);
        _activateProject(minIndex, _projectId);
    }

    /* *************************************************************************************************************************************/
    /* ** Participant Support Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

    function supportProjects(ProjectSupport[] calldata _projectSupports) public {
        uint256 participantBalance = IMimeToken(governanceToken).balanceOf(msg.sender);
        require(participantBalance > 0, "NO_BALANCE_AVAILABLE");

        int256 deltaSupportSum = 0;
        for (uint256 i = 0; i < _projectSupports.length; i++) {
            if (!IProjectList(projectList).projectExists(_projectSupports[i].projectId)) {
                revert ProjectNotInList(_projectSupports[i].projectId);
            }

            deltaSupportSum += _projectSupports[i].deltaSupport;
        }

        uint256 newTotalParticipantSupport = _applyDelta(totalParticipantSupport(msg.sender), deltaSupportSum);
        // Check that the sum of support is not greater than the participant balance
        require(newTotalParticipantSupport <= participantBalance, "NOT_ENOUGH_BALANCE");
        totalParticipantSupportAt[round()][msg.sender] = newTotalParticipantSupport;

        totalSupportAt[round()] = _applyDelta(totalSupport(), deltaSupportSum);

        for (uint256 i = 0; i < _projectSupports.length; i++) {
            uint256 projectId = _projectSupports[i].projectId;
            int256 delta = _projectSupports[i].deltaSupport;

            PoolProject storage project = poolProjects[projectId];

            project.projectSupportAt[round()] = _applyDelta(projectSupport(projectId), delta);
            project.participantSupportAt[round()][msg.sender] =
                _applyDelta(participantSupport(projectId, msg.sender), delta);

            emit ProjectSupportUpdated(round(), projectId, msg.sender, delta);
        }
    }

    function claimAndSupportProjects(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        ProjectSupport[] calldata _projectSupports
    ) external {
        IMimeToken(governanceToken).claim(index, account, amount, merkleProof);
        supportProjects(_projectSupports);
    }

    /* *************************************************************************************************************************************/
    /* ** Flow Syncronization Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

    function sync() external {
        uint256 allowance = ISuperToken(fundingToken).allowance(owner(), address(this));
        if (allowance > 0) {
            ISuperToken(fundingToken).transferFrom(owner(), address(this), allowance);
        }

        uint256 funds = ISuperToken(fundingToken).balanceOf(address(this));

        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            uint256 projectId = activeProjectIds[i];
            if (poolProjects[projectId].flowLastTime == block.timestamp || projectId == 0) {
                continue; // Empty or rates already updated
            }

            // Check the beneficiary doesn't change
            Project memory project = IProjectList(projectList).getProject(projectId);

            address beneficiary = project.beneficiary;
            address oldBeneficiary = poolProjects[projectId].beneficiary;

            if (oldBeneficiary != beneficiary) {
                // Remove the flow from the old beneficiary if it has changed
                if (oldBeneficiary != address(0)) {
                    ICFAv1Forwarder(cfaForwarder).setFlowrate(ISuperToken(fundingToken), oldBeneficiary, 0);
                }
                // We don't have to update the flow rate because it will be updated next
                poolProjects[projectId].beneficiary = beneficiary;
            }

            uint256 currentRate = _getCurrentRate(projectId, funds);
            ICFAv1Forwarder(cfaForwarder).setFlowrate(
                ISuperToken(fundingToken), beneficiary, int96(int256(currentRate))
            );

            poolProjects[projectId].flowLastRate = currentRate;
            poolProjects[projectId].flowLastTime = block.timestamp;

            emit FlowSynced(projectId, beneficiary, currentRate);
        }
    }

    /* *************************************************************************************************************************************/
    /* ** Osmotic Params Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function setOsmoticFormulaParams(OsmoticParams calldata _params) public onlyOwner {
        _setOsmoticParams(_params);
    }

    function setOsmoticFormulaDecay(uint256 _decay) public onlyOwner {
        _setOsmoticDecay(_decay);
    }

    function setOsmoticDrop(uint256 _drop) public onlyOwner {
        _setOsmoticDrop(_drop);
    }

    function setOsmoticMaxFlow(uint256 _minStakeRatio) public onlyOwner {
        _setOsmoticMaxFlow(_minStakeRatio);
    }

    function setOsmoticMinStakeRatio(uint256 _minFlow) public onlyOwner {
        _setOsmoticMinStakeRatio(_minFlow);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function round() public view returns (uint256) {
        return IMimeToken(governanceToken).round();
    }

    function projectSupport(uint256 _projectId) public view returns (uint256) {
        return poolProjects[_projectId].projectSupportAt[round()];
    }

    function participantSupport(uint256 _projectId, address _participant) public view returns (uint256) {
        return poolProjects[_projectId].participantSupportAt[round()][_participant];
    }

    function totalSupport() public view returns (uint256) {
        return totalSupportAt[round()];
    }

    function totalParticipantSupport(address _participant) public view returns (uint256) {
        return totalParticipantSupportAt[round()][_participant];
    }

    function getCurrentRate(uint256 _projectId) external view returns (uint256) {
        return _getCurrentRate(_projectId, ISuperToken(fundingToken).balanceOf(address(this)));
    }

    function getTargetRate(uint256 _projectId) external view returns (uint256) {
        return _getTargetRate(_projectId, ISuperToken(fundingToken).balanceOf(address(this)));
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Project Activation and Deactivation Functions                                                                         ***/
    /* *************************************************************************************************************************************/

    function _activateProject(uint256 _index, uint256 _projectId) internal {
        activeProjectIds[_index] = _projectId;
        poolProjects[_projectId].active = true;
        poolProjects[_projectId].flowLastTime = block.timestamp;

        emit ProjectActivated(_projectId);
    }

    function _deactivateProject(uint256 _index) internal {
        uint256 projectId = activeProjectIds[_index];
        poolProjects[projectId].active = false;
        Project memory project = IProjectList(projectList).getProject(projectId);
        ICFAv1Forwarder(cfaForwarder).setFlowrate(ISuperToken(fundingToken), project.beneficiary, 0);

        emit ProjectDeactivated(projectId);
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Flow Rate Calculation Functions                                                                                       ***/
    /* *************************************************************************************************************************************/

    function _getTargetRate(uint256 _projectId, uint256 _funds) internal view returns (uint256) {
        return calculateTargetRate(_funds, projectSupport(_projectId), totalSupport());
    }

    function _getCurrentRate(uint256 _projectId, uint256 _funds) internal view returns (uint256 _rate) {
        PoolProject storage project = poolProjects[_projectId];
        assert(project.flowLastTime <= block.timestamp);
        uint256 timePassed = block.timestamp - project.flowLastTime;
        return _rate = calculateRate(
            timePassed, // we assert it doesn't overflow above
            project.flowLastRate,
            _getTargetRate(_projectId, _funds)
        );
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Helpers Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/

    function _applyDelta(uint256 _support, int256 _delta) internal pure returns (uint256) {
        int256 result = int256(_support) + _delta;

        if (result < 0) {
            revert SupportUnderflow();
        }
        return uint256(result);
    }
}
