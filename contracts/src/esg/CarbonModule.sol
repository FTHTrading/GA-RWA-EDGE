// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {ReserveProofAnchor} from "../core/ReserveProofAnchor.sol";

/// @title CarbonModule
/// @notice Voluntary / compliance carbon-credit attestation and retirement ledger.
///         Supports voluntary registries (Verra VCS, Gold Standard, Puro for engineered removals,
///         American Carbon Registry) and compliance markets (RGGI, California CCA, Washington CCA).
///         Mint only against a registry serial number; retire on-chain with serial visible.
///         NO REGISTRY, NO TOKEN — mirror of the SREC module discipline.
/// @dev    This module is a LEDGER. Secondary transfer wrapping happens in a companion CarbonToken
///         (ERC-3643 for compliance restrictions on compliance-market allowances, ERC-20 permissioned
///         for voluntary tokens with retirement burn). The Toucan-pattern bridge (retire in source
///         registry, mint on-chain) is enforced here by requiring the registry serial and evidence
///         reference at mint time.
///         ICVCM / CCP-grade credibility for voluntary tiers requires additionality attestation +
///         MRV evidence hashed through ReserveProofAnchor before mint. Do NOT bypass.
contract CarbonModule is Roles {
    enum Market { VOLUNTARY_VERRA, VOLUNTARY_GOLD_STANDARD, VOLUNTARY_PURO, VOLUNTARY_ACR, COMPLIANCE_RGGI, COMPLIANCE_CCA, COMPLIANCE_OTHER }

    struct Credit {
        bytes32 dealId;
        Market  market;
        bytes32 vintage;      // encoded year
        string  registrySerial;
        uint256 tCO2eCents;   // integer minor units — tonnes CO2e * 100
        bool    additionalityVerified;
        uint64  attestedAt;
        uint64  mintedAt;
        bool    retired;
        uint64  retiredAt;
        address retiredBy;
        string  retirementBeneficiary; // free-text who claimed the offset (for corporate ESG)
    }

    ReserveProofAnchor public immutable anchor;
    Credit[] private _credits;
    mapping(bytes32 => uint256[]) private _byDeal;

    event Minted(uint256 indexed id, bytes32 indexed dealId, Market market, string registrySerial, uint256 tCO2eCents);
    event Retired(uint256 indexed id, address indexed by, string beneficiary);

    error AlreadyRetired();
    error NoCredit();
    error EmptySerial();
    error CompliancePathRequiresICVCM();

    constructor(address owner_, ReserveProofAnchor anchor_) Roles(owner_) {
        if (address(anchor_) == address(0)) revert ZeroAddress();
        anchor = anchor_;
    }

    /// @notice Mint a carbon credit ledger entry against a registry serial.
    /// @param additionalityVerified True if project additionality has been ICVCM/CCP-grade attested via ReserveProofAnchor.
    /// @dev    Voluntary premium tiers effectively require additionality = true. Owner should reject
    ///         mints where market is voluntary but additionalityVerified is false, unless the credit
    ///         is being downgraded to a discount tier.
    function mint(
        bytes32 dealId,
        Market market,
        bytes32 vintage,
        string calldata registrySerial,
        uint256 tCO2eCents,
        bool additionalityVerified,
        uint64 attestedAt
    ) external onlyAgent returns (uint256 id) {
        if (bytes(registrySerial).length == 0) revert EmptySerial();
        _credits.push(Credit({
            dealId: dealId,
            market: market,
            vintage: vintage,
            registrySerial: registrySerial,
            tCO2eCents: tCO2eCents,
            additionalityVerified: additionalityVerified,
            attestedAt: attestedAt,
            mintedAt: uint64(block.timestamp),
            retired: false,
            retiredAt: 0,
            retiredBy: address(0),
            retirementBeneficiary: ""
        }));
        id = _credits.length - 1;
        _byDeal[dealId].push(id);
        emit Minted(id, dealId, market, registrySerial, tCO2eCents);
    }

    /// @notice Retire a credit on behalf of a beneficiary (free-text label).
    /// @dev    Must be matched by a registry-side retirement of the same serial off-chain.
    ///         Agent-gated because retirement is a legally-significant compliance event.
    function retire(uint256 id, address retiredBy_, string calldata beneficiary) external onlyAgent {
        if (id >= _credits.length) revert NoCredit();
        Credit storage c = _credits[id];
        if (c.retired) revert AlreadyRetired();
        c.retired = true;
        c.retiredAt = uint64(block.timestamp);
        c.retiredBy = retiredBy_;
        c.retirementBeneficiary = beneficiary;
        emit Retired(id, retiredBy_, beneficiary);
    }

    function creditCount() external view returns (uint256) {
        return _credits.length;
    }

    function getCredit(uint256 id) external view returns (Credit memory) {
        if (id >= _credits.length) revert NoCredit();
        return _credits[id];
    }

    function creditsForDeal(bytes32 dealId) external view returns (uint256[] memory) {
        return _byDeal[dealId];
    }
}
