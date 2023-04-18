// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IProjectList, Project} from "../interfaces/IProjectList.sol";

error UnauthorizedProjectAdmin();
error BeneficiaryAlreadyExists(address beneficiary);

contract ProjectRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable, IProjectList {
    uint256 public immutable version;

    uint256 public nextProjectId;

    mapping(uint256 => Project) projects;
    mapping(address => bool) internal registeredBeneficiaries;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectUpdated(uint256 indexed projectId, address admin, address beneficiary, bytes contenthash);

    /* *************************************************************************************************************************************/
    /* ** Modifiers                                                                                                                      ***/
    /* *************************************************************************************************************************************/

    modifier isValidBeneficiary(address _beneficiary) {
        require(_beneficiary != address(0), "ProjectRegistry: beneficiary cannot be zero address");
        if (registeredBeneficiaries[_beneficiary]) {
            revert BeneficiaryAlreadyExists(_beneficiary);
        }

        _;
    }

    modifier onlyAdmin(uint256 _projectId) {
        if (projects[_projectId].admin != msg.sender) {
            revert UnauthorizedProjectAdmin();
        }

        _;
    }

    constructor(uint256 _version) {
        _disableInitializers();

        version = _version;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        nextProjectId = 1;
    }

    /* *************************************************************************************************************************************/
    /* ** Upgradeability Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* *************************************************************************************************************************************/
    /* ** Project Functions                                                                                                              ***/
    /* *************************************************************************************************************************************/

    function registerProject(address _beneficiary, bytes memory _contenthash)
        public
        isValidBeneficiary(_beneficiary)
        returns (uint256 _projectId)
    {
        _projectId = nextProjectId++;

        _updateProject(_projectId, msg.sender, _beneficiary, _contenthash);
    }

    function updateProject(uint256 _projectId, address _newAdmin, address _beneficiary, bytes calldata _contenthash)
        external
        onlyAdmin(_projectId)
        isValidBeneficiary(_beneficiary)
    {
        require(_newAdmin != address(0), "ProjectRegistry: new admin cannot be zero address");

        _updateProject(_projectId, _newAdmin, _beneficiary, _contenthash);
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Project Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/

    function _updateProject(uint256 _projectId, address _admin, address _beneficiary, bytes memory _contenthash)
        internal
    {
        address oldBeneficiary = projects[_projectId].beneficiary;
        registeredBeneficiaries[oldBeneficiary] = false;

        projects[_projectId] = Project({admin: _admin, beneficiary: _beneficiary, contenthash: _contenthash});
        registeredBeneficiaries[_beneficiary] = true;

        emit ProjectUpdated(_projectId, _admin, _beneficiary, _contenthash);
    }

    /* *************************************************************************************************************************************/
    /* ** IProjectList Functions                                                                                                         ***/
    /* *************************************************************************************************************************************/

    function getProject(uint256 _projectId) public view returns (Project memory) {
        return projects[_projectId];
    }

    function projectExists(uint256 _projectId) external view returns (bool) {
        return projects[_projectId].beneficiary != address(0);
    }
}
