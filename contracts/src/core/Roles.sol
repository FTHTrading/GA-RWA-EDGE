// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

/// @title Roles
/// @notice Minimal two-tier access control used across the LD Capital / LDX suite.
///         OWNER  = governance (multisig/timelock) — topology + policy changes.
///         AGENT  = operational actor(s) — mint/burn/freeze/distribute.
/// @dev    Owner/agent separation is a hard Unykorn invariant: never collapse both
///         onto a single EOA. Owner SHOULD be a multisig; agents MAY be automation
///         keys with velocity limits enforced upstream (BitGo/Fireblocks policy).
abstract contract Roles {
    address public owner;
    mapping(address => bool) public isAgent;

    event OwnershipTransferred(address indexed prev, address indexed next);
    event AgentSet(address indexed agent, bool enabled);

    error NotOwner();
    error NotAgent();
    error ZeroAddress();

    constructor(address owner_) {
        if (owner_ == address(0)) revert ZeroAddress();
        owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAgent() {
        if (!isAgent[msg.sender]) revert NotAgent();
        _;
    }

    function transferOwnership(address next) external onlyOwner {
        if (next == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, next);
        owner = next;
    }

    function setAgent(address agent, bool enabled) external onlyOwner {
        if (agent == address(0)) revert ZeroAddress();
        isAgent[agent] = enabled;
        emit AgentSet(agent, enabled);
    }
}
