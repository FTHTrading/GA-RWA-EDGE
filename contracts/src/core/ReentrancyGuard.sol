// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

/// @title ReentrancyGuard
/// @notice Minimal non-reentrancy guard (1 = unlocked, 2 = locked). Defense-in-depth on
///         paths that make external token calls; checks-effects-interactions remains the
///         primary control.
abstract contract ReentrancyGuard {
    uint256 private _status = 1;
    error Reentrant();

    modifier nonReentrant() {
        if (_status == 2) revert Reentrant();
        _status = 2;
        _;
        _status = 1;
    }
}
