// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {IIdentityRegistry} from "../interfaces/ICompliance.sol";

/// @title IdentityRegistry
/// @notice Binds wallets to an off-chain/ONCHAINID identity and records the set of
///         verified claim topics (KYC=1, AML=2, ACCREDITED=3, ...). `isVerified` returns
///         true only when the wallet carries EVERY required topic and is not revoked.
/// @dev    Non-custodial identity: the registry binds and can revoke, but never holds the
///         investor's ONCHAINID key. In full production this delegates to on-chain
///         ONCHAINID claim verification (see erc3643-tokenomics isVerified pattern); here
///         the agent (KYC provider integration: Persona + Parallel Markets) sets topic
///         bits after off-chain verification. Topic set is required-topics driven.
contract IdentityRegistry is Roles, IIdentityRegistry {
    uint256 public constant TOPIC_KYC = 1;
    uint256 public constant TOPIC_AML = 2;
    uint256 public constant TOPIC_ACCREDITED = 3;

    struct Identity {
        bytes32 onchainId;   // reference to the investor's ONCHAINID
        uint16  country;     // ISO 3166-1 numeric
        uint256 topicsBits;  // bit i set => topic i satisfied
        bool    exists;
    }

    mapping(address => Identity) private _id;
    uint256[] public requiredTopics;

    event IdentityRegistered(address indexed wallet, bytes32 onchainId, uint16 country);
    event IdentityDeleted(address indexed wallet);
    event TopicSet(address indexed wallet, uint256 topic, bool satisfied);
    event RequiredTopicsUpdated(uint256[] topics);

    error AlreadyRegistered();
    error NotRegistered();

    constructor(address owner_, uint256[] memory requiredTopics_) Roles(owner_) {
        requiredTopics = requiredTopics_;
        emit RequiredTopicsUpdated(requiredTopics_);
    }

    function setRequiredTopics(uint256[] calldata topics) external onlyOwner {
        requiredTopics = topics;
        emit RequiredTopicsUpdated(topics);
    }

    function registerIdentity(address wallet, bytes32 onchainId, uint16 country)
        external
        override
        onlyAgent
    {
        if (wallet == address(0)) revert ZeroAddress();
        if (_id[wallet].exists) revert AlreadyRegistered();
        _id[wallet] = Identity({onchainId: onchainId, country: country, topicsBits: 0, exists: true});
        emit IdentityRegistered(wallet, onchainId, country);
    }

    function deleteIdentity(address wallet) external override onlyAgent {
        if (!_id[wallet].exists) revert NotRegistered();
        delete _id[wallet];
        emit IdentityDeleted(wallet);
    }

    /// @notice Agent records that a KYC provider satisfied a claim topic for this wallet.
    function setTopic(address wallet, uint256 topic, bool satisfied) external onlyAgent {
        if (!_id[wallet].exists) revert NotRegistered();
        uint256 mask = uint256(1) << topic;
        if (satisfied) _id[wallet].topicsBits |= mask;
        else _id[wallet].topicsBits &= ~mask;
        emit TopicSet(wallet, topic, satisfied);
    }

    function isVerified(address wallet) external view override returns (bool) {
        Identity storage id = _id[wallet];
        if (!id.exists) return false;
        uint256 topics = id.topicsBits;
        uint256 len = requiredTopics.length;
        for (uint256 i; i < len; ++i) {
            if (topics & (uint256(1) << requiredTopics[i]) == 0) return false;
        }
        return true;
    }

    function investorCountry(address wallet) external view override returns (uint16) {
        return _id[wallet].country;
    }

    function identityOf(address wallet)
        external
        view
        returns (bytes32 onchainId, uint16 country, uint256 topicsBits, bool exists)
    {
        Identity storage id = _id[wallet];
        return (id.onchainId, id.country, id.topicsBits, id.exists);
    }
}
