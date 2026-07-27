// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";

/// @title AMLTravelRuleGate
/// @notice On-chain compliance gate every value-moving flow passes through. Composes four
///         decisions, folded to the worst outcome (BLOCK > REVIEW > ALLOW):
///           1. Sanctions screening (OFAC/SDN) — a hit is a hard BLOCK.
///           2. KYC/KYB terminal-state check — parties must be APPROVED and unexpired.
///           3. FATF Travel Rule — at/above threshold a travelRuleRef must be present.
///           4. Transaction monitoring — deterministic structuring / velocity / high-risk
///              jurisdiction rules route to REVIEW.
/// @dev    FAIL CLOSED: unknown parties default to REVIEW, sanctions default to BLOCK.
///         Off-chain screening (aml-kyc-travel-rule skill) sets the on-chain state; this
///         contract is the deterministic enforcement surface consumers revert on. Amounts
///         are in the caller's integer minor units; `travelRuleThreshold` is set to match.
contract AMLTravelRuleGate is Roles {
    enum Decision { ALLOW, REVIEW, BLOCK }         // ordinal = severity (fold by max)
    enum Kyc { UNSTARTED, PENDING, REVIEW, APPROVED, REJECTED, EXPIRED }

    // ---- screening state (set by compliance agent from off-chain gate output) ----
    mapping(address => bool) public sanctioned;
    mapping(address => Kyc) public kyc;
    mapping(address => uint64) public kycExpiry;    // 0 = no expiry
    mapping(address => uint16) public jurisdiction; // ISO-3166 numeric

    mapping(uint16 => bool) public highRiskJurisdiction; // -> REVIEW (EDD)
    mapping(uint16 => bool) public blockedJurisdiction;  // -> BLOCK (embargo)

    // ---- policy config (owner; policy-owned constants) ----
    uint256 public travelRuleThreshold;  // minor units; 0 disables the trigger
    uint256 public velocityWindow;       // seconds
    uint256 public velocityMax;          // max settled value per window per party
    uint256 public structuringBand;      // amount within [thr-band, thr) is "near"
    bool public monitoringOn = true;

    // ---- monitoring state (per party) ----
    struct Window { uint64 start; uint256 sum; }
    mapping(address => Window) private _vel;      // rolling velocity per party
    mapping(address => uint64) private _lastNear; // last near-threshold ts per party

    // authorized consumers may advance monitoring state via evaluate()
    mapping(address => bool) public isConsumer;

    event Screened(address indexed party, bool sanctioned, Kyc kyc, uint64 expiry, uint16 juris);
    event JurisdictionRisk(uint16 country, bool highRisk, bool blocked);
    event PolicySet(uint256 threshold, uint256 velWindow, uint256 velMax, uint256 band, bool monitoring);
    event ConsumerSet(address indexed consumer, bool enabled);
    event Evaluated(address indexed from, address indexed to, uint256 amount, Decision decision, string code);

    error NotConsumer();

    constructor(
        address owner_,
        uint256 travelRuleThreshold_,
        uint256 velocityWindow_,
        uint256 velocityMax_,
        uint256 structuringBand_
    ) Roles(owner_) {
        travelRuleThreshold = travelRuleThreshold_;
        velocityWindow = velocityWindow_;
        velocityMax = velocityMax_;
        structuringBand = structuringBand_;
        emit PolicySet(travelRuleThreshold_, velocityWindow_, velocityMax_, structuringBand_, true);
    }

    // ---- admin ----
    function setConsumer(address c, bool enabled) external onlyOwner {
        isConsumer[c] = enabled;
        emit ConsumerSet(c, enabled);
    }

    function setPolicy(
        uint256 threshold,
        uint256 velWindow,
        uint256 velMax,
        uint256 band,
        bool monitoring
    ) external onlyOwner {
        travelRuleThreshold = threshold;
        velocityWindow = velWindow;
        velocityMax = velMax;
        structuringBand = band;
        monitoringOn = monitoring;
        emit PolicySet(threshold, velWindow, velMax, band, monitoring);
    }

    function setJurisdictionRisk(uint16 country, bool highRisk, bool blocked) external onlyOwner {
        highRiskJurisdiction[country] = highRisk;
        blockedJurisdiction[country] = blocked;
        emit JurisdictionRisk(country, highRisk, blocked);
    }

    // ---- compliance agent screening updates ----
    function setScreening(
        address party,
        bool sanctioned_,
        Kyc kyc_,
        uint64 expiry,
        uint16 juris
    ) external onlyAgent {
        sanctioned[party] = sanctioned_;
        kyc[party] = kyc_;
        kycExpiry[party] = expiry;
        jurisdiction[party] = juris;
        emit Screened(party, sanctioned_, kyc_, expiry, juris);
    }

    // ---- decision logic (pure view; no state change) ----
    function _kycOk(address p) internal view returns (bool) {
        if (kyc[p] != Kyc.APPROVED) return false;
        uint64 exp = kycExpiry[p];
        if (exp != 0 && block.timestamp > exp) return false;
        return true;
    }

    /// @notice Pure preview of the decision without advancing monitoring state.
    function preview(address from, address to, uint256 amount, bytes32 travelRuleRef)
        public
        view
        returns (Decision decision, string memory code)
    {
        // 1. Sanctions — hard BLOCK (both parties).
        if (sanctioned[from] || sanctioned[to]) return (Decision.BLOCK, "OFAC_SDN_MATCH");
        if (blockedJurisdiction[jurisdiction[from]] || blockedJurisdiction[jurisdiction[to]]) {
            return (Decision.BLOCK, "EMBARGOED_JURISDICTION");
        }

        Decision worst = Decision.ALLOW;
        string memory wcode = "OK";

        // 2. KYC/KYB terminal state — beneficiary always; originator when not a mint.
        if (!_kycOk(to)) { worst = Decision.REVIEW; wcode = "KYC_BENEFICIARY_NOT_APPROVED"; }
        if (from != address(0) && !_kycOk(from) && worst != Decision.BLOCK) {
            worst = Decision.REVIEW; wcode = "KYC_ORIGINATOR_NOT_APPROVED";
        }

        // 3. Travel Rule — at/above threshold requires a reference.
        if (travelRuleThreshold != 0 && amount >= travelRuleThreshold && travelRuleRef == bytes32(0)) {
            worst = Decision.REVIEW; wcode = "TRAVEL_RULE_REQUIRED";
        }

        // 4. Monitoring — high-risk jurisdiction EDD.
        if (monitoringOn) {
            if (highRiskJurisdiction[jurisdiction[from]] || highRiskJurisdiction[jurisdiction[to]]) {
                worst = worst < Decision.REVIEW ? Decision.REVIEW : worst;
                if (worst == Decision.REVIEW && _isOk(wcode)) wcode = "HIGH_RISK_JURISDICTION";
            }
            // velocity (view estimate)
            if (velocityMax != 0) {
                Window storage w = _vel[from];
                uint256 projected = (block.timestamp - w.start > velocityWindow) ? amount : w.sum + amount;
                if (projected > velocityMax) {
                    worst = worst < Decision.REVIEW ? Decision.REVIEW : worst;
                    if (worst == Decision.REVIEW && _isOk(wcode)) wcode = "VELOCITY_EXCEEDED";
                }
            }
            // structuring: near-threshold now and a prior near tx within window
            if (_isNear(amount)) {
                uint64 last = _lastNear[from];
                if (last != 0 && block.timestamp - last <= velocityWindow) {
                    worst = worst < Decision.REVIEW ? Decision.REVIEW : worst;
                    if (worst == Decision.REVIEW && _isOk(wcode)) wcode = "STRUCTURING_PATTERN";
                }
            }
        }
        return (worst, wcode);
    }

    /// @notice State-advancing evaluation used by consumers at settlement time. Advances
    ///         velocity + structuring counters, then returns the decision.
    function evaluate(address from, address to, uint256 amount, bytes32 travelRuleRef)
        external
        returns (Decision decision, string memory code)
    {
        if (!isConsumer[msg.sender]) revert NotConsumer();
        (decision, code) = preview(from, to, amount, travelRuleRef);

        // advance monitoring state regardless of outcome (audit continuity)
        if (from != address(0)) {
            Window storage w = _vel[from];
            if (block.timestamp - w.start > velocityWindow) {
                w.start = uint64(block.timestamp);
                w.sum = amount;
            } else {
                w.sum += amount;
            }
            if (_isNear(amount)) _lastNear[from] = uint64(block.timestamp);
        }
        emit Evaluated(from, to, amount, decision, code);
    }

    function _isNear(uint256 amount) internal view returns (bool) {
        if (travelRuleThreshold == 0 || structuringBand == 0) return false;
        return amount >= travelRuleThreshold - structuringBand && amount < travelRuleThreshold;
    }

    function _isOk(string memory s) internal pure returns (bool) {
        return keccak256(bytes(s)) == keccak256(bytes("OK"));
    }
}
