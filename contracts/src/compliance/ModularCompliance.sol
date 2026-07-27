// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {IModularCompliance, IComplianceModule} from "../interfaces/ICompliance.sol";

/// @title ModularCompliance
/// @notice Binds pluggable compliance modules to one token. `canTransfer` is true only
///         when EVERY bound module approves. State hooks forward to modules so they can
///         track holder counts, lockups, and balances. Policy changes = module edits,
///         never token redeploys.
contract ModularCompliance is Roles, IModularCompliance {
    address public override token;
    address[] public modules;
    mapping(address => bool) public isBound;

    event TokenBound(address indexed token);
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);

    error TokenAlreadyBound();
    error NotToken();
    error ModuleAlreadyBound();
    error ModuleNotBound();

    constructor(address owner_) Roles(owner_) {}

    modifier onlyToken() {
        if (msg.sender != token) revert NotToken();
        _;
    }

    function bindToken(address token_) external onlyOwner {
        if (token != address(0)) revert TokenAlreadyBound();
        if (token_ == address(0)) revert ZeroAddress();
        token = token_;
        emit TokenBound(token_);
    }

    function addModule(address module) external onlyOwner {
        if (module == address(0)) revert ZeroAddress();
        if (isBound[module]) revert ModuleAlreadyBound();
        isBound[module] = true;
        modules.push(module);
        emit ModuleAdded(module);
    }

    function removeModule(address module) external onlyOwner {
        if (!isBound[module]) revert ModuleNotBound();
        isBound[module] = false;
        uint256 n = modules.length;
        for (uint256 i; i < n; ++i) {
            if (modules[i] == module) {
                modules[i] = modules[n - 1];
                modules.pop();
                break;
            }
        }
        emit ModuleRemoved(module);
    }

    function moduleCount() external view returns (uint256) {
        return modules.length;
    }

    function canTransfer(address from, address to, uint256 amount)
        external
        view
        override
        returns (bool)
    {
        uint256 n = modules.length;
        for (uint256 i; i < n; ++i) {
            if (!IComplianceModule(modules[i]).moduleCheck(from, to, amount, token)) {
                return false;
            }
        }
        return true;
    }

    function created(address to, uint256 amount) external override onlyToken {
        uint256 n = modules.length;
        for (uint256 i; i < n; ++i) {
            IComplianceModule(modules[i]).moduleMintAction(to, amount, token);
        }
    }

    function destroyed(address from, uint256 amount) external override onlyToken {
        uint256 n = modules.length;
        for (uint256 i; i < n; ++i) {
            IComplianceModule(modules[i]).moduleBurnAction(from, amount, token);
        }
    }

    function transferred(address from, address to, uint256 amount) external override onlyToken {
        uint256 n = modules.length;
        for (uint256 i; i < n; ++i) {
            IComplianceModule(modules[i]).moduleTransferAction(from, to, amount, token);
        }
    }
}
