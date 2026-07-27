// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../core/Roles.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title AsyncVault (ERC-7540-style skeleton)
/// @notice Asynchronous request/pending/claimable/claimed vault lifecycle for RWA products where
///         settlement is not same-block. Investor calls `requestDeposit` or `requestRedeem`; the
///         controller (typically the pool operator + AttestationAgent) fulfills against
///         off-chain NAV / compliance / eligibility checks; then investor claims the resulting shares
///         or assets. Matches the pattern LD Capital uses for compute-note pools and Centrifuge V3
///         graduation.
/// @dev    This is a MINIMAL SEED. Production version must implement full ERC-7540:
///           - ERC-165 interface support
///           - `share()` returning the address of the paired ERC-3643 Share Token
///           - `pendingDepositRequest` / `claimableDepositRequest` view helpers per request id
///           - Interaction with a compliance gate (IdentityRegistry / ModularCompliance) BEFORE claim
///           - Precise integer minor-unit math and decimal normalization
///           - Integration with ERC-7887 (request cancellation) and ERC-8161 (transferable requests)
///         Do not deploy this skeleton to any chain that touches investor value. It exists to seed
///         the interface shape for the Solidity team + audit scope.
contract AsyncVault is Roles {
    enum Stage { NONE, PENDING, CLAIMABLE, CLAIMED, CANCELLED }

    enum Kind { DEPOSIT, REDEEM }

    struct Request {
        Kind    kind;
        address controller;   // wallet that will fulfill / cancel
        address owner;        // beneficial owner of the pending position
        address asset;        // ERC-20 deposited (for DEPOSIT) or share token burned (for REDEEM)
        uint256 amount;       // raw units of the asset
        uint256 fulfilled;    // shares to mint (DEPOSIT) or assets to release (REDEEM)
        uint64  createdAt;
        Stage   stage;
    }

    IERC20 public immutable shareToken;   // the ERC-3643 Share Token (compliance lives here)
    Request[] private _requests;

    event RequestOpened(uint256 indexed id, Kind kind, address indexed owner, address asset, uint256 amount);
    event RequestFulfilled(uint256 indexed id, uint256 fulfilled);
    event RequestClaimed(uint256 indexed id);
    event RequestCancelled(uint256 indexed id);

    // NotOwner() and ZeroAddress() are inherited from Roles — do not redeclare.
    error NotRequestOwner();
    error NotClaimable();
    error NotPending();
    error TransferFailed();
    error ZeroAmount();

    constructor(address owner_, IERC20 shareToken_) Roles(owner_) {
        if (address(shareToken_) == address(0)) revert ZeroAddress();
        shareToken = shareToken_;
    }

    /// @notice Investor requests to deposit `amount` of `asset` in exchange for shares.
    /// @dev    The asset is escrowed here until the request is fulfilled or cancelled.
    function requestDeposit(address asset, uint256 amount, address controller_) external returns (uint256 id) {
        if (amount == 0) revert ZeroAmount();
        // Pull the asset into escrow. Requires prior approval.
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (!ok) revert TransferFailed(); // reuse error; real code emits explicit TransferFailed
        _requests.push(Request({
            kind: Kind.DEPOSIT,
            controller: controller_,
            owner: msg.sender,
            asset: asset,
            amount: amount,
            fulfilled: 0,
            createdAt: uint64(block.timestamp),
            stage: Stage.PENDING
        }));
        id = _requests.length - 1;
        emit RequestOpened(id, Kind.DEPOSIT, msg.sender, asset, amount);
    }

    /// @notice Investor requests to redeem `shares`.
    /// @dev    Shares are pulled into escrow at request time; released on cancel or burned on claim.
    function requestRedeem(uint256 shares, address controller_) external returns (uint256 id) {
        if (shares == 0) revert ZeroAmount();
        bool ok = shareToken.transferFrom(msg.sender, address(this), shares);
        if (!ok) revert TransferFailed();
        _requests.push(Request({
            kind: Kind.REDEEM,
            controller: controller_,
            owner: msg.sender,
            asset: address(shareToken),
            amount: shares,
            fulfilled: 0,
            createdAt: uint64(block.timestamp),
            stage: Stage.PENDING
        }));
        id = _requests.length - 1;
        emit RequestOpened(id, Kind.REDEEM, msg.sender, address(shareToken), shares);
    }

    /// @notice Controller fulfills a pending request. For DEPOSIT: sets shares to mint on claim.
    ///         For REDEEM: sets assets to release on claim. Actual mint / release happens on `claim`
    ///         so compliance gates can re-check at that moment.
    function fulfill(uint256 id, uint256 fulfilled) external onlyAgent {
        Request storage r = _requests[id];
        if (r.stage != Stage.PENDING) revert NotPending();
        r.fulfilled = fulfilled;
        r.stage = Stage.CLAIMABLE;
        emit RequestFulfilled(id, fulfilled);
    }

    /// @notice Investor claims a fulfilled request. Deposit &rarr; mint shares. Redeem &rarr; release asset.
    /// @dev    Implementation stub: the actual mint/burn/release call is left to production because it
    ///         depends on the Share Token's mint interface (ERC-3643 permissioned mint via ModularCompliance).
    function claim(uint256 id) external {
        Request storage r = _requests[id];
        if (r.stage != Stage.CLAIMABLE) revert NotClaimable();
        if (msg.sender != r.owner) revert NotRequestOwner();
        r.stage = Stage.CLAIMED;
        // PRODUCTION TODO:
        //   if (r.kind == Kind.DEPOSIT) {
        //     shareToken.mint(r.owner, r.fulfilled)  // subject to compliance gate
        //   } else {
        //     IERC20(underlyingAsset).transfer(r.owner, r.fulfilled)  // and burn escrowed shares
        //   }
        emit RequestClaimed(id);
    }

    /// @notice Cancel a still-pending request. ERC-7887-style; owner or controller only.
    function cancel(uint256 id) external {
        Request storage r = _requests[id];
        if (r.stage != Stage.PENDING) revert NotPending();
        if (msg.sender != r.owner && msg.sender != r.controller) revert NotRequestOwner();
        r.stage = Stage.CANCELLED;
        // Refund escrow
        bool ok = IERC20(r.asset).transfer(r.owner, r.amount);
        if (!ok) revert TransferFailed();
        emit RequestCancelled(id);
    }

    function requestCount() external view returns (uint256) {
        return _requests.length;
    }

    function getRequest(uint256 id) external view returns (Request memory) {
        return _requests[id];
    }
}
