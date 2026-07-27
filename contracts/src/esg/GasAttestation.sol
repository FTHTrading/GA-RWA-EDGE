// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {ReserveProofAnchor} from "../core/ReserveProofAnchor.sol";

/// @title GasAttestation
/// @notice Ledger for natural-gas generation / offtake used as bridge or hybrid power for edge
///         data-center sites. Records per-period generation, fuel source, and emissions attestation
///         so that gas-hybrid sites can operate transparently within the FTH stack without
///         compromising the ESG evidence chain.
/// @dev    Gas is a legitimate bridge power source when paired with (a) full emissions attestation,
///         (b) clear disclosure to QROF investors, and (c) a documented transition path to lower-carbon
///         supply. This ledger records the FACTS; it does NOT make policy judgments about acceptable
///         emissions intensity. Owner + policy layer (off-chain) enforces thresholds.
///         Every period record must reference an off-chain evidence hash anchored via
///         ReserveProofAnchor (invoice, meter reading, methane-capture cert if applicable).
contract GasAttestation is Roles {
    enum FuelSource { PIPELINE_NATURAL_GAS, STRANDED_GAS, FLARED_GAS_CAPTURED, LNG, RNG_BIOGAS, MIXED }

    struct Period {
        bytes32 dealId;
        uint64  periodStart;
        uint64  periodEnd;
        FuelSource fuel;
        uint256 mwhGeneratedCents;   // integer minor units — MWh * 100
        uint256 mmbtuCents;          // fuel consumed in MMBtu * 100
        uint256 kgCO2eCents;         // scope 1 emissions in kg CO2e * 100 (attested)
        bytes32 evidenceHash;        // hash of invoice + meter + emissions cert (in ReserveProofAnchor)
        uint64  attestedAt;
    }

    ReserveProofAnchor public immutable anchor;
    Period[] private _periods;
    mapping(bytes32 => uint256[]) private _byDeal;

    event PeriodRecorded(
        uint256 indexed id,
        bytes32 indexed dealId,
        FuelSource fuel,
        uint256 mwhGeneratedCents,
        uint256 kgCO2eCents
    );

    error NoPeriod();
    error EmptyEvidence();

    constructor(address owner_, ReserveProofAnchor anchor_) Roles(owner_) {
        if (address(anchor_) == address(0)) revert ZeroAddress();
        anchor = anchor_;
    }

    /// @notice Record a gas generation / offtake period with full emissions attestation.
    ///         The evidenceHash MUST match a prior anchor in ReserveProofAnchor for the deal.
    /// @dev    Enforcement of "evidenceHash exists in ReserveProofAnchor" is left to the calling
    ///         agent for gas efficiency — the anchor's append-only history means the hash is either
    ///         verifiable at read time or the agent's write is a compliance breach visible in the
    ///         event log. Do not weaken this discipline in production.
    function record(
        bytes32 dealId,
        uint64 periodStart,
        uint64 periodEnd,
        FuelSource fuel,
        uint256 mwhGeneratedCents,
        uint256 mmbtuCents,
        uint256 kgCO2eCents,
        bytes32 evidenceHash
    ) external onlyAgent returns (uint256 id) {
        if (evidenceHash == bytes32(0)) revert EmptyEvidence();
        _periods.push(Period({
            dealId: dealId,
            periodStart: periodStart,
            periodEnd: periodEnd,
            fuel: fuel,
            mwhGeneratedCents: mwhGeneratedCents,
            mmbtuCents: mmbtuCents,
            kgCO2eCents: kgCO2eCents,
            evidenceHash: evidenceHash,
            attestedAt: uint64(block.timestamp)
        }));
        id = _periods.length - 1;
        _byDeal[dealId].push(id);
        emit PeriodRecorded(id, dealId, fuel, mwhGeneratedCents, kgCO2eCents);
    }

    function periodCount() external view returns (uint256) {
        return _periods.length;
    }

    function getPeriod(uint256 id) external view returns (Period memory) {
        if (id >= _periods.length) revert NoPeriod();
        return _periods[id];
    }

    function periodsForDeal(bytes32 dealId) external view returns (uint256[] memory) {
        return _byDeal[dealId];
    }

    /// @notice Convenience helper — carbon intensity of a period in kg CO2e per MWh generated.
    /// @dev    Both inputs are stored as integer minor units (*100); the ratio is dimensionally clean.
    ///         Returns 0 if generation is 0 to avoid division-by-zero.
    function carbonIntensity(uint256 id) external view returns (uint256 kgCO2ePerMWhCents) {
        if (id >= _periods.length) revert NoPeriod();
        Period memory p = _periods[id];
        if (p.mwhGeneratedCents == 0) return 0;
        // (kgCO2eCents / mwhGeneratedCents) with cents cancelling — result is kg CO2e per MWh
        return (p.kgCO2eCents * 100) / p.mwhGeneratedCents;
    }
}
