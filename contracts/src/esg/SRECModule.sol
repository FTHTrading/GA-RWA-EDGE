// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {ReserveProofAnchor} from "../core/ReserveProofAnchor.sol";

/// @title SRECModule
/// @notice Solar Renewable Energy Certificate (SREC) attestation and retirement ledger.
///         Each certificate represents 1 MWh of qualifying solar generation, tied to a state-registry
///         serial (M-RETS, PJM-GATS, ERCOT, NC-RETS, etc.). Meter attestations from revenue-grade
///         meters produce the underlying MWh count; ReserveProofAnchor stores the evidence hash;
///         this module mints a fungible unit per attested MWh and burns it on retirement.
/// @dev    IMPORTANT: this is a certificate LEDGER, not an ERC-20 token. Full ERC-3643 wrapping for
///         secondary transfer / distribution happens in a companion RECToken contract that references
///         this module for issuance eligibility. The retirement burn here is the terminal event that
///         must reconcile to the state registry's serial-level retirement.
///         Georgia has NO SREC compliance market (no RPS) — GA-generated units flow through this
///         module as voluntary/bilateral certificates. PJM-state (VA/PA/MD/NJ/OH/IL/DC/DE) units
///         are compliance-market SRECs. Serial-level provenance MUST be maintained per unit.
contract SRECModule is Roles {
    struct Certificate {
        bytes32 dealId;       // which SPE generated the MWh
        bytes32 vintage;      // encoded generation year (e.g., keccak256("2027"))
        bytes32 registry;     // state registry identifier (keccak256("PJM-GATS") etc.)
        string  serial;       // state registry serial number (per unit)
        uint256 mwhCents;     // integer minor units — MWh * 100 to preserve precision
        uint64  attestedAt;   // meter attestation timestamp
        uint64  mintedAt;     // ledger mint timestamp
        bool    retired;
        uint64  retiredAt;
        address retiredBy;
    }

    ReserveProofAnchor public immutable anchor;
    Certificate[] private _certificates;
    mapping(bytes32 => uint256[]) private _byDeal;

    event Minted(
        uint256 indexed id,
        bytes32 indexed dealId,
        bytes32 registry,
        string serial,
        uint256 mwhCents
    );
    event Retired(uint256 indexed id, address indexed by);

    error AlreadyRetired();
    error NoCertificate();
    error EmptySerial();

    constructor(address owner_, ReserveProofAnchor anchor_) Roles(owner_) {
        if (address(anchor_) == address(0)) revert ZeroAddress();
        anchor = anchor_;
    }

    /// @notice Mint a certificate against an attested meter reading. Agent-gated; the attestation
    ///         itself is proven via ReserveProofAnchor (referenced off-chain by evidenceRef).
    /// @param dealId       Deal / SPE identifier (matches DealRegistry entry)
    /// @param vintage      keccak-encoded generation year
    /// @param registry     keccak-encoded state registry identifier
    /// @param serial       Registry serial number for the certificate (per-unit provenance)
    /// @param mwhCents     Generated MWh * 100 (integer minor units)
    /// @param attestedAt   Timestamp of the meter attestation
    function mint(
        bytes32 dealId,
        bytes32 vintage,
        bytes32 registry,
        string calldata serial,
        uint256 mwhCents,
        uint64 attestedAt
    ) external onlyAgent returns (uint256 id) {
        if (bytes(serial).length == 0) revert EmptySerial();
        _certificates.push(Certificate({
            dealId: dealId,
            vintage: vintage,
            registry: registry,
            serial: serial,
            mwhCents: mwhCents,
            attestedAt: attestedAt,
            mintedAt: uint64(block.timestamp),
            retired: false,
            retiredAt: 0,
            retiredBy: address(0)
        }));
        id = _certificates.length - 1;
        _byDeal[dealId].push(id);
        emit Minted(id, dealId, registry, serial, mwhCents);
    }

    /// @notice Retire a certificate — terminal event. Must reconcile to a state-registry
    ///         retirement of the same serial number off-chain.
    /// @dev    Agent-gated because retirement is a compliance event; the calling agent is
    ///         responsible for confirming the registry-side retirement before executing.
    function retire(uint256 id, address retiredBy_) external onlyAgent {
        if (id >= _certificates.length) revert NoCertificate();
        Certificate storage c = _certificates[id];
        if (c.retired) revert AlreadyRetired();
        c.retired = true;
        c.retiredAt = uint64(block.timestamp);
        c.retiredBy = retiredBy_;
        emit Retired(id, retiredBy_);
    }

    function certificateCount() external view returns (uint256) {
        return _certificates.length;
    }

    function getCertificate(uint256 id) external view returns (Certificate memory) {
        if (id >= _certificates.length) revert NoCertificate();
        return _certificates[id];
    }

    function certificatesForDeal(bytes32 dealId) external view returns (uint256[] memory) {
        return _byDeal[dealId];
    }
}
