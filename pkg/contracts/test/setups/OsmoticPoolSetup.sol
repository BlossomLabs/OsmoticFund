// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {MimeToken} from "mime-token/MimeToken.sol";

import {ProjectUtils} from "../utils/ProjectUtils.sol";
import {BaseSetup} from "../setups/BaseSetup.sol";

import {OsmoticController} from "../../src/OsmoticController.sol";
import {OsmoticPool, ProjectSupport} from "../../src/OsmoticPool.sol";
import {IProjectList} from "../../src/interfaces/IProjectList.sol";
import {ProjectRegistry} from "../../src/projects/ProjectRegistry.sol";

abstract contract OsmoticPoolSetup is BaseSetup {
    uint256 constant MAX_ACTIVE_PROJECTS = 25;

    MimeToken mimeToken;
    OsmoticController controller;
    OsmoticPool pool;
    ProjectRegistry projectRegistry;
    IProjectList projectList;

    address poolOwner;

    uint256[] projectIds;

    function setUp() public virtual override {
        super.setUp();

        (, address projectRegistryAddress) = createProjectRegistry(VERSION);
        projectRegistry = ProjectRegistry(projectRegistryAddress);
        projectList = IProjectList(projectRegistry);

        (, address controllerAddress) = createOsmoticControllerAndPoolImpl(
            VERSION, projectRegistryAddress, MIME_TOKEN_FACTORY_ADDRESS, ROUND_DURATION, CFA_V1_FORWARDER_ADDRESS
        );
        controller = OsmoticController(controllerAddress);
        address mimeTokenAddress = createMimeTokenFromController(controllerAddress, MERKLE_ROOT);
        mimeToken = MimeToken(mimeTokenAddress);

        _claimMimeTokens(mimeToken);

        pool = OsmoticPool(
            createOsmoticPoolFromController(
                controllerAddress, FUNDING_TOKEN_ADDRESS, mimeTokenAddress, address(projectList), OSMOTIC_PARAMS
            )
        );

        poolOwner = pool.owner();
    }

    function _createProject() internal returns (uint256) {
        uint256 projectId = createProjectInRegistry(projectRegistry);

        projectIds.push(projectId);

        return projectId;
    }

    function _createProjects(uint256 _numProjects) internal {
        for (uint256 i = projectIds.length; i < _numProjects; i++) {
            _createProject();
        }
    }

    function _supportProject(address _account, uint256 _projectId, int256 _supportDelta) internal {
        ProjectSupport[] memory participantSupports = new ProjectSupport[](1);
        participantSupports[0] = ProjectSupport(_projectId, _supportDelta);

        vm.prank(_account);
        pool.supportProjects(participantSupports);
    }

    function _supportAllProjects(address _account, int256 _supportDelta) internal {
        ProjectSupport[] memory participantSupports = new ProjectSupport[](pool.MAX_ACTIVE_PROJECTS());

        for (uint256 i = 0; i < projectIds.length; i++) {
            participantSupports[i] = ProjectSupport(projectIds[i], _supportDelta);
        }

        vm.prank(_account);
        pool.supportProjects(participantSupports);
    }

    function _activateAllProjects() internal {
        for (uint256 i = 0; i < projectIds.length; i++) {
            pool.activateProject(projectIds[i]);
        }
    }

    function _processFuzzedSupports(
        address mimeHolder,
        int32[MAX_ACTIVE_PROJECTS] memory _fuzzedSupports,
        uint256 _supportsLength,
        bool _onlyPositiveSupports,
        bool _onlyNonZeroSupports
    ) internal returns (ProjectSupport[] memory projectSupports) {
        vm.assume(_fuzzedSupports.length > 0);
        uint256 supportsLength = bound(_fuzzedSupports.length, 1, _supportsLength);

        // Set balance to maximum
        vm.mockCall(
            address(mimeToken),
            abi.encodeWithSelector(MimeToken.balanceOf.selector, address(mimeHolder)),
            abi.encode(type(uint256).max)
        );

        projectSupports = new ProjectSupport[](supportsLength);

        for (uint256 i = 0; i < supportsLength; i++) {
            int256 delta;

            if (_onlyPositiveSupports) {
                delta = int256(uint256(uint32(_fuzzedSupports[i])));
            } else {
                delta = int256(_fuzzedSupports[i]);
            }

            if (_onlyNonZeroSupports && delta == 0) {
                delta = 1;
            }

            projectSupports[i].projectId = _createProject();
            projectSupports[i].deltaSupport = delta * 1e18;
        }
    }
}
