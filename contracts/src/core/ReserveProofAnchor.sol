// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";
import {AttestationVerifier} from "./AttestationVerifier.sol";

/// @title ReserveProofAnchor
/// @notice Append-only registry of reserve/collateral proofs for LD Capital instruments.
///         Anchors the SHA-256 hash of an off-chain reserve document (SBLC, custody
///         receipt, appraisal, attestor letter) AND the attestor's signed USD value via
///         the oracle m-of-n quorum. Public, immutable, timestamped.
/// @dev    IMPORTANT SCOPE: this contract proves a document EXISTS and an allowlisted
///         attestor SIGNED a value at a time. It is NOT a legal lien or perfected security
///         interest — legal collateralization (SPV + security agreement + control
///         agreement + counsel opinion) lives off-chain and is referenced by `legalRef`.
///         Do not represent an anchor as enforceable collateral.
contract ReserveProofAnchor is Roles {
    struct ProofEntry {
        bytes32 reserveId;      // keccak256 of instrument/pool id
        bytes32 docHash;        // SHA-256 of the reserve document (as bytes32)
        int256  valueUsdCents;  // attested reserve value, USD cents (quorum median)
        uint64  observedAt;     // attestation observation time
        uint64  anchoredAt;     // block time of anchoring
        string  docURI;         // off-chain evidence pointer (ipfs://, https://)
        string  legalRef;       // off-chain legal package id (SPV / security agreement)
    }

    AttestationVerifier public immutable verifier;
    bytes32 public constant CLAIM_RESERVE_USD = keccak256("RESERVE_USD");
    bytes32 public constant UNIT_USD_CENTS = keccak256("USD_CENTS");

    // reserveId => ordered history of proofs (append-only; never overwritten)
    mapping(bytes32 => ProofEntry[]) private _history;

    event ReserveAnchored(
        bytes32 indexed reserveId,
        bytes32 docHash,
        int256 valueUsdCents,
        uint256 index,
        string docURI
    );

    error EmptyReserveId();
    error EmptyDocHash();
    error ClaimMismatch();

    constructor(address owner_, AttestationVerifier verifier_) Roles(owner_) {
        verifier = verifier_;
    }

    /// @notice Anchor a new reserve proof. The value is established by an m-of-n oracle
    ///         quorum over RESERVE_USD attestations, so no single attestor can set it.
    /// @dev    Agent-gated write; the quorum + guards in the verifier are the real trust.
    function anchor(
        bytes32 reserveId,
        bytes32 docHash,
        string calldata docURI,
        string calldata legalRef,
        AttestationVerifier.Attestation[] calldata items,
        bytes[] calldata sigs
    ) external onlyAgent returns (uint256 index) {
        if (reserveId == bytes32(0)) revert EmptyReserveId();
        if (docHash == bytes32(0)) revert EmptyDocHash();
        // Bind the quorum to this reserve + the RESERVE_USD claim.
        if (items[0].subject != reserveId || items[0].claim != CLAIM_RESERVE_USD) {
            revert ClaimMismatch();
        }
        int256 medianUsdCents = verifier.verifyQuorum(items, sigs);

        ProofEntry memory e = ProofEntry({
            reserveId: reserveId,
            docHash: docHash,
            valueUsdCents: medianUsdCents,
            observedAt: items[0].timestamp,
            anchoredAt: uint64(block.timestamp),
            docURI: docURI,
            legalRef: legalRef
        });
        _history[reserveId].push(e);
        index = _history[reserveId].length - 1;
        emit ReserveAnchored(reserveId, docHash, medianUsdCents, index, docURI);
    }

    function latest(bytes32 reserveId) external view returns (ProofEntry memory) {
        ProofEntry[] storage h = _history[reserveId];
        require(h.length > 0, "no proof");
        return h[h.length - 1];
    }

    function proofCount(bytes32 reserveId) external view returns (uint256) {
        return _history[reserveId].length;
    }

    function proofAt(bytes32 reserveId, uint256 index) external view returns (ProofEntry memory) {
        return _history[reserveId][index];
    }
}
