// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../../core/Roles.sol";
import {IComplianceModule} from "../../interfaces/ICompliance.sol";

/// @title ModuleBase
/// @notice Shared plumbing for compliance modules. State-mutating hooks may only be
///         called by the bound ModularCompliance for the given token.
abstract contract ModuleBase is Roles, IComplianceModule {
    // token => ModularCompliance authorized to push state hooks for that token
    mapping(address => address) public complianceOf;

    event ComplianceBound(address indexed token, address indexed compliance);

    error NotCompliance();

    constructor(address owner_) Roles(owner_) {}

    function bindCompliance(address token, address compliance) external onlyOwner {
        if (token == address(0) || compliance == address(0)) revert ZeroAddress();
        complianceOf[token] = compliance;
        emit ComplianceBound(token, compliance);
    }

    modifier onlyCompliance(address token) {
        if (msg.sender != complianceOf[token]) revert NotCompliance();
        _;
    }

    // Default no-op hooks; modules override the ones they need.
    function moduleMintAction(address, uint256, address token) external virtual override onlyCompliance(token) {}
    function moduleBurnAction(address, uint256, address token) external virtual override onlyCompliance(token) {}
    function moduleTransferAction(address, address, uint256, address token)
        external
        virtual
        override
        onlyCompliance(token)
    {}
}
