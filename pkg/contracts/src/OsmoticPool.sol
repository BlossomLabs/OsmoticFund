// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OsmoticFormula, OsmoticParams} from "./OsmoticFormula.sol";
import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";
import {ProjectRegistry} from "./ProjectRegistry.sol";

error ProjectNotFound(uint256 projectId);

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

    event PoolProjectRegistered(uint256 _projectId);

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

    function _registerProject(uint256 _projectId) internal {
        poolProjects[_projectId].registered = true;

        emit PoolProjectRegistered(_projectId);
    }

    function _checkProject(uint256 _projectId) internal view {
        if (!projectRegistry.projectExists(_projectId)) {
            revert ProjectNotFound(_projectId);
        }
    }
}
