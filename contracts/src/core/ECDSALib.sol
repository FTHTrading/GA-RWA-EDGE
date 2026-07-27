// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

/// @title ECDSALib
/// @notice Canonical-only ECDSA recovery. Rejects high-s (EIP-2 malleability) and
///         non-{27,28} v, so a signature maps to exactly one canonical form. This is
///         load-bearing for the attestation nonce/replay logic.
library ECDSALib {
    error BadSignatureLength();
    error HighS();
    error BadV();
    error ZeroSigner();

    /// @dev secp256k1 half-order n/2. s must be <= this or the signature is malleable.
    uint256 internal constant HALF_N =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    function recover(bytes32 digest, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) revert BadSignatureLength();
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
        if (uint256(s) > HALF_N) revert HighS();
        if (v != 27 && v != 28) revert BadV();
        address signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) revert ZeroSigner();
        return signer;
    }
}
