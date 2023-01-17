// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OsmoticFormula, OsmoticParams} from "./OsmoticFormula.sol";
import {ProjectRegistry} from "./ProjectRegistry.sol";
import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";

error ProjectNotFound(uint256 projectId);
error ProjectAlreadyActive(uint256 projectId);
error ProjectNeedsMoreStake(uint256 projectId, uint256 requiredStake, uint256 currentStake);

contract OsmoticPool is Initializable, OwnableUpgradeable, UUPSUpgradeable, OsmoticFormula {
    uint256 public immutable version;
    ICFAv1Forwarder public immutable cfaForwarder;

    uint8 constant MAX_ACTIVE_PROJECTS = 15;

    address public fundingToken;
    address public governanceToken;

    OsmoticParams public osmoticParams;
    ProjectRegistry public projectRegistry;

    struct PoolProject {
        uint256 totalSupport;
        uint256 flowLastRate;
        uint256 flowLastTime;
        bool active;
        bool registered;
        mapping(address => uint256) participantSupports;
    }

    // projectId => project
    mapping(uint256 => PoolProject) public poolProjects;
    mapping(address => uint256) internal totalParticipantSupport;
    uint256[MAX_ACTIVE_PROJECTS] internal activeProjectIds;

    event ProjectRegistered(uint256 indexed projectId);
    event ProjectActivated(uint256 indexed id);
    event ProjectDeactivated(uint256 indexed id);

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 _version, ICFAv1Forwarder _cfaForwarder) {
        version = _version;
        cfaForwarder = _cfaForwarder;
        _disableInitializers();
    }

    function initialize(OsmoticParams memory _params, ProjectRegistry _projectRegistry) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __OsmoticFormula_init(_params);

        projectRegistry = _projectRegistry;
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setPoolSettings(OsmoticParams memory _params) public onlyOwner {
        _setOsmoticParams(_params);
    }

    function registerProject(uint256 _projectId) public {
        _checkProject(_projectId);

        _registerProject(_projectId);
    }

    function registerProjects(uint256[] memory _projectIds) public onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            _checkProject(projectId);
            _registerProject(projectId);
        }
    }

    function activateProject(uint256 _projectId) public {
        require(poolProjects[_projectId].registered);

        uint256 minSupport = poolProjects[_projectId].totalSupport;
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
            if (poolProjects[activeProjectIds[i]].totalSupport < minSupport) {
                minSupport = poolProjects[activeProjectIds[i]].totalSupport;
                minIndex = i;
            }
        }

        if (activeProjectIds[minIndex] == _projectId) {
            revert ProjectNeedsMoreStake(_projectId, minSupport, poolProjects[_projectId].totalSupport);
        }

        if (activeProjectIds[minIndex] == 0) {
            _activateProject(minIndex, _projectId);
            return;
        }

        _deactivateProject(minIndex);
        _activateProject(minIndex, _projectId);
    }

    function _registerProject(uint256 _projectId) internal {
        poolProjects[_projectId].registered = true;

        emit ProjectRegistered(_projectId);
    }

    function _checkProject(uint256 _projectId) internal view {
        if (!projectRegistry.projectExists(_projectId)) {
            revert ProjectNotFound(_projectId);
        }
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
}
