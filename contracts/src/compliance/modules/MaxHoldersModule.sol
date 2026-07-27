// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {ModuleBase} from "./ModuleBase.sol";

/// @title MaxHoldersModule
/// @notice Caps the number of distinct holders (e.g. Reg D / 3(c) beneficial-owner
///         limits). Blocks a transfer/mint that would onboard a NEW holder beyond the
///         cap; existing holders are always fine. Maintains its own balance shadow so
///         holder count stays exact across mint/burn/transfer.
contract MaxHoldersModule is ModuleBase {
    mapping(address => uint256) public maxHolders;                 // token => cap
    mapping(address => uint256) public holderCount;               // token => current
    mapping(address => mapping(address => uint256)) private _bal; // token => holder => shadow bal

    event MaxSet(address indexed token, uint256 cap);

    error CapBelowCurrent();

    constructor(address owner_) ModuleBase(owner_) {}

    function setMax(address token, uint256 cap) external onlyOwner {
        if (cap < holderCount[token]) revert CapBelowCurrent();
        maxHolders[token] = cap;
        emit MaxSet(token, cap);
    }

    function moduleCheck(address, address to, uint256 amount, address token)
        external
        view
        override
        returns (bool)
    {
        if (amount == 0) return true;
        if (_bal[token][to] != 0) return true; // existing holder
        return holderCount[token] + 1 <= maxHolders[token];
    }

    function moduleMintAction(address to, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        if (amount == 0) return;
        if (_bal[token][to] == 0) holderCount[token] += 1;
        _bal[token][to] += amount;
    }

    function moduleBurnAction(address from, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        if (amount == 0) return;
        _bal[token][from] -= amount;
        if (_bal[token][from] == 0 && holderCount[token] > 0) holderCount[token] -= 1;
    }

    function moduleTransferAction(address from, address to, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        if (amount == 0) return;
        if (_bal[token][to] == 0) holderCount[token] += 1;
        _bal[token][to] += amount;
        _bal[token][from] -= amount;
        if (_bal[token][from] == 0 && holderCount[token] > 0) holderCount[token] -= 1;
    }

    function shadowBalance(address token, address holder) external view returns (uint256) {
        return _bal[token][holder];
    }
}
