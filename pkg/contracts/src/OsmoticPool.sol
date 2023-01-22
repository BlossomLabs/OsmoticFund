// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";

import {ProjectRegistry} from "./ProjectRegistry.sol";
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

    uint8 constant MAX_ACTIVE_PROJECTS = 15;
    uint8 constant MAX_PARTICIPANT_UPDATES = 10;

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

    OsmoticController controller;
    IERC20 public fundingToken;
    IERC20 public governanceToken;
    OsmoticParams public osmoticParams;
    ProjectRegistry public projectRegistry;
    uint256 public totalSupport;

    // projectId => PoolProject
    mapping(uint256 => PoolProject) public poolProjects;

    mapping(address => uint256) internal totalParticipantSupport;

    uint256[MAX_ACTIVE_PROJECTS] internal activeProjectIds;

    event ProjectIncluded(uint256 indexed projectId);
    event ProjectRemoved(uint256 indexed projectId);
    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event FlowSynced(uint256 indexed projectId, address beneficiary, uint256 flowRate);
    event ProjectSupportChanged(uint256 indexed projectId, address participant, int256 delta);

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICFAv1Forwarder _cfaForwarder) {
        cfaForwarder = _cfaForwarder;
        _disableInitializers();
    }

    function initialize(
        OsmoticController _controller,
        IERC20 _fundingToken,
        IERC20 _governanceToken,
        OsmoticParams calldata _params,
        ProjectRegistry _projectRegistry
    ) public initializer {
        __Ownable_init();
        __OsmoticFormula_init(_params);

        controller = _controller;
        fundingToken = _fundingToken;
        governanceToken = _governanceToken;
        projectRegistry = _projectRegistry;
    }

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

    function addProject(uint256 _projectId) public onlyOwner {
        _addProject(_projectId);
    }

    function addProjects(uint256[] calldata _projectIds) public onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            _addProject(projectId);
        }
    }

    function removeProjects(uint256[] calldata _projectIds) public onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            _removeProject(projectId);
        }
    }

    function removeProject(uint256 _projectId) public onlyOwner {
        _removeProject(_projectId);
    }

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

    function sync() external {
        // TODO: consider using allowance() + balanceOf()
        uint256 funds = fundingToken.balanceOf(address(this));
        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            uint256 projectId = activeProjectIds[i];
            if (poolProjects[projectId].flowLastTime == block.timestamp || projectId == 0) {
                continue; // Empty or rates already updated
            }

            // Check the beneficiary doesn't change
            (address beneficiary,) = projectRegistry.getProject(projectId);
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

    /**
     * @dev Support with an amount of tokens on a proposal
     */
    function changeProjectSupports(ParticipantSupportUpdate[] calldata _participantUpdates) external {
        require(_participantUpdates.length <= MAX_PARTICIPANT_UPDATES, "UPDATES_EXCEEDS_MAX");

        uint256 availableStake = controller.getParticipantStaking(msg.sender, address(governanceToken));

        require(availableStake > 0, "NO_STAKE_AVAILABLE");

        // We store the old support to check if we need to notify the controller
        uint256 oldTotalParticipantSupport = totalParticipantSupport[msg.sender];

        int256 deltaSupportSum = 0;
        // Check that the sum of supports is not greater than the available stake
        for (uint256 i = 0; i < _participantUpdates.length; i++) {
            deltaSupportSum += _participantUpdates[i].deltaSupport;
        }

        uint256 newTotalParticipantSupport = _applyDelta(totalParticipantSupport[msg.sender], deltaSupportSum);

        totalParticipantSupport[msg.sender] = newTotalParticipantSupport;

        require(newTotalParticipantSupport <= availableStake, "NOT_ENOUGH_STAKE");

        totalSupport = _applyDelta(totalSupport, deltaSupportSum);

        for (uint256 i = 0; i < _participantUpdates.length; i++) {
            uint256 projectId = _participantUpdates[i].projectId;
            int256 delta = _participantUpdates[i].deltaSupport;

            _checkProject(projectId);
            // TODO: maybe we'll use this function along with withdraw so we need to set supports to 0 in the future
            require(delta != 0, "SUPPORT_CAN_NOT_BE_ZERO");

            PoolProject storage project = poolProjects[projectId];

            uint256 projectParticipantSupport = project.participantSupports[msg.sender];

            project.projectSupport = _applyDelta(project.projectSupport, delta);
            project.participantSupports[msg.sender] = _applyDelta(projectParticipantSupport, delta);

            emit ProjectSupportChanged(projectId, msg.sender, delta);
        }

        // Notify the controller if the user is now supporting or unsupporting projects
        if (oldTotalParticipantSupport > 0 && newTotalParticipantSupport == 0) {
            controller.decreaseParticipantSupportedPools(msg.sender, address(this));
        } else if (oldTotalParticipantSupport == 0 && newTotalParticipantSupport > 0) {
            controller.increaseParticipantSupportedPools(msg.sender, address(this));
        }
    }

    function getCurrentRate(uint256 _projectId) external view returns (uint256) {
        return _getCurrentRate(_projectId, fundingToken.balanceOf(address(this)));
    }

    function getTargetRate(uint256 _projectId) external view returns (uint256) {
        return _getTargetRate(_projectId, fundingToken.balanceOf(address(this)));
    }

    function _checkProject(uint256 _projectId) internal view {
        if (!projectRegistry.projectExists(_projectId)) {
            revert ProjectNotFound(_projectId);
        }
    }

    function _addProject(uint256 _projectId) internal {
        _checkProject(_projectId);
        poolProjects[_projectId].included = true;

        emit ProjectIncluded(_projectId);
    }

    function _removeProject(uint256 _projectId) internal {
        _checkProject(_projectId);
        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                _deactivateProject(i);
                poolProjects[_projectId].included = false;

                emit ProjectRemoved(_projectId);
                return;
            }
        }

        revert ProjectNotIncluded(_projectId);
    }

    function _activateProject(uint256 _index, uint256 _projectId) internal {
        activeProjectIds[_index] = _projectId;
        poolProjects[_projectId].active = true;
        poolProjects[_projectId].flowLastTime = block.timestamp;

        emit ProjectActivated(_projectId);
    }

    function _deactivateProject(uint256 _index) internal {
        uint256 projectId = activeProjectIds[_index];
        poolProjects[projectId].active = false;
        (address oldBeneficiary,) = projectRegistry.getProject(projectId);
        cfaForwarder.setFlowrate(fundingToken, oldBeneficiary, 0);

        emit ProjectDeactivated(projectId);
    }

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

    function _applyDelta(uint256 _support, int256 _delta) internal pure returns (uint256) {
        int256 result = int256(_support) + _delta;

        if (result < 0) {
            revert SupportUnderflow();
        }
        return uint256(result);
    }
}
