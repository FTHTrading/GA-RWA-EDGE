// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";
import {ECDSALib} from "./ECDSALib.sol";

/// @title AttestationVerifier
/// @notice Canonical Unykorn oracle primitive. Brings off-chain facts on-chain as
///         EIP-712 signed attestations with an allowlist, per-(signer,subject) nonce
///         replay guard, a staleness window, and m-of-n median aggregation.
/// @dev    Every downstream path (reserve proof, construction draw, SREC, price feed)
///         imports THIS instead of rolling its own signing. Fails closed.
contract AttestationVerifier is Roles {
    using ECDSALib for bytes32;

    struct Attestation {
        bytes32 subject;   // keccak256 id of the thing (drawId, meterId, reserveId)
        bytes32 claim;     // keccak256 of claim type ("RESERVE_USD", "MILESTONE_BPS")
        int256  value;     // signed measurement, integer minor units
        bytes32 unit;      // keccak256 unit tag ("USD_CENTS","BASIS_POINTS","WH")
        uint64  timestamp; // unix seconds of observation
        uint256 nonce;     // strictly increasing per (signer, subject)
    }

    bytes32 public constant ATTESTATION_TYPEHASH = keccak256(
        "Attestation(bytes32 subject,bytes32 claim,int256 value,bytes32 unit,uint64 timestamp,uint256 nonce)"
    );

    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => bool) public isOracle;
    uint256 public threshold;                                   // m (min distinct signers)
    uint256 public stalenessWindow;                             // seconds
    mapping(address => mapping(bytes32 => uint256)) public lastNonce; // signer => subject => nonce

    event OracleSet(address indexed oracle, bool enabled);
    event ThresholdSet(uint256 threshold);
    event StalenessSet(uint256 seconds_);
    event Verified(address indexed signer, bytes32 indexed subject, bytes32 claim, int256 value);

    error StaleAttestation();
    error NonceNotIncreasing();
    error NotAllowlisted();
    error QuorumNotMet();
    error SubjectClaimMismatch();
    error DuplicateSigner();
    error BadThreshold();

    constructor(address owner_, uint256 threshold_, uint256 stalenessWindow_) Roles(owner_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("UnykornOracle")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        if (threshold_ == 0) revert BadThreshold();
        threshold = threshold_;
        stalenessWindow = stalenessWindow_;
        emit ThresholdSet(threshold_);
        emit StalenessSet(stalenessWindow_);
    }

    function setOracle(address oracle, bool enabled) external onlyOwner {
        if (oracle == address(0)) revert ZeroAddress();
        isOracle[oracle] = enabled;
        emit OracleSet(oracle, enabled);
    }

    function setThreshold(uint256 m) external onlyOwner {
        if (m == 0) revert BadThreshold();
        threshold = m;
        emit ThresholdSet(m);
    }

    function setStaleness(uint256 s) external onlyOwner {
        stalenessWindow = s;
        emit StalenessSet(s);
    }

    function _hash(Attestation calldata a) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(ATTESTATION_TYPEHASH, a.subject, a.claim, a.value, a.unit, a.timestamp, a.nonce)
        );
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /// @notice Verify one attestation, enforce all guards, and consume the nonce.
    /// @dev    State-mutating (advances nonce). Reverts on any guard failure (fail closed).
    function verify(Attestation calldata a, bytes calldata sig) public returns (address signer) {
        signer = _hash(a).recover(sig);
        if (!isOracle[signer]) revert NotAllowlisted();
        if (block.timestamp - a.timestamp > stalenessWindow) revert StaleAttestation();
        if (a.nonce <= lastNonce[signer][a.subject]) revert NonceNotIncreasing();
        lastNonce[signer][a.subject] = a.nonce;
        emit Verified(signer, a.subject, a.claim, a.value);
    }

    /// @notice Pure view of the digest for off-chain signer parity / dry-run checks.
    function digestOf(Attestation calldata a) external view returns (bytes32) {
        return _hash(a);
    }

    /// @notice Verify a quorum of attestations for the SAME (subject, claim); require
    ///         >= threshold distinct allowlisted signers; return the MEDIAN value.
    function verifyQuorum(Attestation[] calldata items, bytes[] calldata sigs)
        external
        returns (int256 medianValue)
    {
        uint256 n = items.length;
        if (n != sigs.length || n < threshold) revert QuorumNotMet();
        address[] memory seen = new address[](n);
        int256[] memory vals = new int256[](n);
        for (uint256 i; i < n; ++i) {
            if (items[i].subject != items[0].subject || items[i].claim != items[0].claim) {
                revert SubjectClaimMismatch();
            }
            address signer = verify(items[i], sigs[i]);
            for (uint256 j; j < i; ++j) {
                if (seen[j] == signer) revert DuplicateSigner();
            }
            seen[i] = signer;
            vals[i] = items[i].value;
        }
        return _median(vals);
    }

    /// @dev Insertion sort a memory copy; return middle (odd) or average of the two
    ///      middle elements (even). Integer average via signed floor division is fine
    ///      here — inputs are bounded oracle readings, not adversarial overflow vectors.
    function _median(int256[] memory arr) internal pure returns (int256) {
        uint256 n = arr.length;
        for (uint256 i = 1; i < n; ++i) {
            int256 key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                unchecked { --j; }
            }
            arr[j] = key;
        }
        if (n % 2 == 1) return arr[n / 2];
        return (arr[n / 2 - 1] + arr[n / 2]) / 2;
    }
}
