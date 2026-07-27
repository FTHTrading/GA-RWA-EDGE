// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";

/// @title DealRegistry
/// @notice Canonical index of every LD Capital deal and the on-chain contracts that
///         implement it. One shared identity/compliance core serves many instruments;
///         this registry records which token/waterfall/reserve belong to each deal and its
///         lifecycle status, so LDX, reporting, and audit have a single source of truth.
/// @dev    Registry-only (records addresses); deployment stays explicit per path so
///         bytecode and audit scope stay bounded. Agent records; owner sets status.
contract DealRegistry is Roles {
    enum Status { DRAFT, STRUCTURING, OPEN, FUNDED, SERVICING, MATURED, DEFAULTED, CLOSED }
    enum PathKind { CMBS, PRIVATE_CREDIT, RWA, REIT, ENERGY, MTN, NEOBANK }

    struct Deal {
        bytes32 dealId;
        PathKind path;
        address securityToken;   // LDSecurityToken or tranche root
        address waterfall;       // CMBSWaterfall / distributor (0 if n/a)
        bytes32 reserveId;       // key into ReserveProofAnchor (0 if n/a)
        Status  status;
        uint64  createdAt;
        string  legalRef;        // off-chain SPV / offering package id
        bool    exists;
    }

    mapping(bytes32 => Deal) private _deals;
    bytes32[] public dealIds;

    event DealRegistered(bytes32 indexed dealId, PathKind path, address token, address waterfall);
    event DealStatus(bytes32 indexed dealId, Status status);
    event DealContractsUpdated(bytes32 indexed dealId, address token, address waterfall, bytes32 reserveId);

    error DealExists();
    error NoDeal();

    constructor(address owner_) Roles(owner_) {}

    function registerDeal(
        bytes32 dealId,
        PathKind path,
        address securityToken,
        address waterfall,
        bytes32 reserveId,
        string calldata legalRef
    ) external onlyAgent {
        if (_deals[dealId].exists) revert DealExists();
        _deals[dealId] = Deal({
            dealId: dealId,
            path: path,
            securityToken: securityToken,
            waterfall: waterfall,
            reserveId: reserveId,
            status: Status.DRAFT,
            createdAt: uint64(block.timestamp),
            legalRef: legalRef,
            exists: true
        });
        dealIds.push(dealId);
        emit DealRegistered(dealId, path, securityToken, waterfall);
    }

    function setStatus(bytes32 dealId, Status status) external onlyOwner {
        if (!_deals[dealId].exists) revert NoDeal();
        _deals[dealId].status = status;
        emit DealStatus(dealId, status);
    }

    function updateContracts(bytes32 dealId, address token, address waterfall, bytes32 reserveId)
        external
        onlyOwner
    {
        Deal storage d = _deals[dealId];
        if (!d.exists) revert NoDeal();
        d.securityToken = token;
        d.waterfall = waterfall;
        d.reserveId = reserveId;
        emit DealContractsUpdated(dealId, token, waterfall, reserveId);
    }

    function getDeal(bytes32 dealId) external view returns (Deal memory) {
        if (!_deals[dealId].exists) revert NoDeal();
        return _deals[dealId];
    }

    function dealCount() external view returns (uint256) {
        return dealIds.length;
    }
}
