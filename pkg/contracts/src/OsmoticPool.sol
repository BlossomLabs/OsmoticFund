// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";
import {IProjectList, Project, ProjectNotInList} from "./interfaces/IProjectList.sol";
import {OsmoticFormula, OsmoticParams} from "./OsmoticFormula.sol";
import {OsmoticController} from "./OsmoticController.sol";

error SupportUnderflow();
error ProjectNotFound(uint256 projectId);
error ProjectNotIncluded(uint256 projectId);
error ProjectAlreadyActive(uint256 projectId);
error ProjectNeedsMoreStake(uint256 projectId, uint256 requiredStake, uint256 currentStake);

struct ParticipantSupportUpdate {
    uint256 projectId;
    int256 deltaSupport;
}

contract OsmoticPool is Initializable, OwnableUpgradeable, OsmoticFormula {
    ICFAv1Forwarder public immutable cfaForwarder;
    OsmoticController public immutable controller;
    IProjectList public immutable projectList;

    uint8 constant MAX_ACTIVE_PROJECTS = 25;

    /* *************************************************************************************************************************************/
    /* ** Structs                                                                                                                        ***/
    /* *************************************************************************************************************************************/

    struct PoolProject {
        uint256 projectSupport;
        uint256 flowLastRate;
        uint256 flowLastTime;
        bool active;
        bool included;
        /**
         * We need to keep track of the beneficiary address in the pool because
         * can be updated in the ProjectRegistry
         */
        address beneficiary;
        mapping(address => uint256) participantSupports;
    }

    IERC20 public fundingToken;
    IERC20 public governanceToken;
    OsmoticParams public osmoticParams;
    uint256 public totalSupport;

    // projectId => PoolProject
    mapping(uint256 => PoolProject) public poolProjects;

    mapping(address => uint256) internal totalParticipantSupport;

    uint256[MAX_ACTIVE_PROJECTS] internal activeProjectIds;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectIncluded(uint256 indexed projectId);
    event ProjectRemoved(uint256 indexed projectId);
    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(uint256 indexed projectId, address participant, int256 delta);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);

    constructor(ICFAv1Forwarder _cfaForwarder, OsmoticController _controller, IProjectList _projectList) {
        _disableInitializers();

        cfaForwarder = _cfaForwarder;
        controller = _controller;
        projectList = _projectList;
    }

    function initialize(IERC20 _fundingToken, IERC20 _governanceToken, OsmoticParams calldata _params)
        public
        initializer
    {
        __Ownable_init();
        __OsmoticFormula_init(_params);

        fundingToken = _fundingToken;
        governanceToken = _governanceToken;
    }

    /* *************************************************************************************************************************************/
    /* ** Project Activation Function                                                                                                    ***/
    /* *************************************************************************************************************************************/

    function activateProject(uint256 _projectId) public {
        require(poolProjects[_projectId].included);

        uint256 minSupport = poolProjects[_projectId].projectSupport;
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
            if (poolProjects[activeProjectIds[i]].projectSupport < minSupport) {
                minSupport = poolProjects[activeProjectIds[i]].projectSupport;
                minIndex = i;
            }
        }

        if (activeProjectIds[minIndex] == _projectId) {
            revert ProjectNeedsMoreStake(_projectId, minSupport, poolProjects[_projectId].projectSupport);
        }

        if (activeProjectIds[minIndex] == 0) {
            _activateProject(minIndex, _projectId);
            return;
        }

        _deactivateProject(minIndex);
        _activateProject(minIndex, _projectId);
    }

    /* *************************************************************************************************************************************/
    /* ** Participant Support Updating Function                                                                                                    ***/
    /* *************************************************************************************************************************************/

    /**
     * @dev Support with an amount of tokens on a proposal
     */
    function updateProjectSupports(ParticipantSupportUpdate[] calldata _participantUpdates) external {
        uint256 availableStake = controller.getParticipantStaking(msg.sender, address(governanceToken));

        require(availableStake > 0, "NO_STAKE_AVAILABLE");

        // We store the old support to check if we need to notify the controller
        uint256 oldTotalParticipantSupport = totalParticipantSupport[msg.sender];

        int256 deltaSupportSum = 0;
        // Check that the sum of supports is not greater than the available stake
        for (uint256 i = 0; i < _participantUpdates.length; i++) {
            if (!projectList.projectExists(_participantUpdates[i].projectId)) {
                revert ProjectNotInList(_participantUpdates[i].projectId);
            }

            deltaSupportSum += _participantUpdates[i].deltaSupport;
        }

        uint256 newTotalParticipantSupport = _applyDelta(totalParticipantSupport[msg.sender], deltaSupportSum);

        totalParticipantSupport[msg.sender] = newTotalParticipantSupport;

        require(newTotalParticipantSupport <= availableStake, "NOT_ENOUGH_STAKE");

        totalSupport = _applyDelta(totalSupport, deltaSupportSum);

        for (uint256 i = 0; i < _participantUpdates.length; i++) {
            uint256 projectId = _participantUpdates[i].projectId;
            int256 delta = _participantUpdates[i].deltaSupport;

            PoolProject storage project = poolProjects[projectId];

            uint256 projectParticipantSupport = project.participantSupports[msg.sender];

            project.projectSupport = _applyDelta(project.projectSupport, delta);
            project.participantSupports[msg.sender] = _applyDelta(projectParticipantSupport, delta);

            emit ProjectSupportUpdated(projectId, msg.sender, delta);
        }

        // Notify the controller if the user is now supporting or unsupporting projects
        if (oldTotalParticipantSupport > 0 && newTotalParticipantSupport == 0) {
            controller.decreaseParticipantSupportedPools(msg.sender, address(this));
        } else if (oldTotalParticipantSupport == 0 && newTotalParticipantSupport > 0) {
            controller.increaseParticipantSupportedPools(msg.sender, address(this));
        }
    }

    /* *************************************************************************************************************************************/
    /* ** Flow Syncronization Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

    function sync() external {
        uint256 allowance = fundingToken.allowance(owner(), address(this));
        if (allowance > 0) {
            fundingToken.transferFrom(owner(), address(this), allowance);
        }

        uint256 funds = fundingToken.balanceOf(address(this));

        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            uint256 projectId = activeProjectIds[i];
            if (poolProjects[projectId].flowLastTime == block.timestamp || projectId == 0) {
                continue; // Empty or rates already updated
            }

            // Check the beneficiary doesn't change
            Project memory project = projectList.getProject(projectId);

            address beneficiary = project.beneficiary;
            address oldBeneficiary = poolProjects[projectId].beneficiary;

            if (oldBeneficiary != beneficiary) {
                // Remove the flow from the old beneficiary if it has changed
                if (oldBeneficiary != address(0)) {
                    cfaForwarder.setFlowrate(fundingToken, oldBeneficiary, 0);
                }
                // We don't have to update the flow rate because it will be updated next
                poolProjects[projectId].beneficiary = beneficiary;
            }

            uint256 currentRate = _getCurrentRate(projectId, funds);
            cfaForwarder.setFlowrate(fundingToken, beneficiary, int96(int256(currentRate)));

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

    function getCurrentRate(uint256 _projectId) external view returns (uint256) {
        return _getCurrentRate(_projectId, fundingToken.balanceOf(address(this)));
    }

    function getTargetRate(uint256 _projectId) external view returns (uint256) {
        return _getTargetRate(_projectId, fundingToken.balanceOf(address(this)));
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
        Project memory project = projectList.getProject(projectId);
        cfaForwarder.setFlowrate(fundingToken, project.beneficiary, 0);

        emit ProjectDeactivated(projectId);
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Flow Rate Calculation Functions                                                                                       ***/
    /* *************************************************************************************************************************************/

    function _getTargetRate(uint256 _projectId, uint256 _funds) internal view returns (uint256) {
        return calculateTargetRate(_funds, poolProjects[_projectId].projectSupport, totalSupport);
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
