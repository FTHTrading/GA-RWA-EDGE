// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "./Roles.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title FeeCollector
/// @notice Routes Unykorn LLC technology fees off deals and vaults into the Unykorn treasury.
///         Fee kinds are enumerated so accounting is transparent per invoice line and per deal.
///         Unykorn earns technology fees (setup / SaaS / per-attestation / per-distribution / per-issuance) —
///         NEVER transaction-based securities compensation. Placement / distribution fees for third-party
///         securities are a separate rail owned by FTH Trading (BD-of-record in Stage 1, own BD in Stage 2+)
///         and MUST NOT be routed through this contract.
/// @dev    Non-custodial by intent: this contract holds no long-term balances. Callers pull-pay in ERC-20
///         (typically USDC or a permissioned stablecoin) and the collector immediately forwards to the
///         treasury address. Owner can rotate the treasury and enable/disable fee kinds. Agent records
///         invoices and executes collections.
contract FeeCollector is Roles {
    enum FeeKind {
        SETUP,           // one-time per-deal spin-up
        SAAS_MONTHLY,    // recurring per live SPE / fund
        ATTESTATION,     // per ReserveProofAnchor.anchor()
        DISTRIBUTION,    // per CMBSWaterfall.distribute()
        ISSUANCE_BPS,    // basis points on token issuance amount
        LICENSE          // outside-operator rail license (setup + monthly)
    }

    struct Invoice {
        bytes32 dealId;
        FeeKind kind;
        address payer;      // SPE or fund entity paying
        address token;      // ERC-20 fee token (typically USDC)
        uint256 amount;     // raw token amount, native decimals
        uint64  timestamp;
        bool    paid;
    }

    address public treasury;
    mapping(FeeKind => bool) public feeEnabled;
    Invoice[] private _invoices;

    event TreasurySet(address indexed prev, address indexed next);
    event FeeKindSet(FeeKind indexed kind, bool enabled);
    event InvoiceRecorded(uint256 indexed id, bytes32 indexed dealId, FeeKind kind, uint256 amount);
    event InvoicePaid(uint256 indexed id, address indexed token, uint256 amount);

    error InvalidTreasury();
    error KindDisabled();
    error AlreadyPaid();
    error NoInvoice();
    error TransferFailed();

    constructor(address owner_, address treasury_) Roles(owner_) {
        if (treasury_ == address(0)) revert InvalidTreasury();
        treasury = treasury_;
        // Default: all fee kinds enabled. Owner can disable per operational policy.
        feeEnabled[FeeKind.SETUP] = true;
        feeEnabled[FeeKind.SAAS_MONTHLY] = true;
        feeEnabled[FeeKind.ATTESTATION] = true;
        feeEnabled[FeeKind.DISTRIBUTION] = true;
        feeEnabled[FeeKind.ISSUANCE_BPS] = true;
        feeEnabled[FeeKind.LICENSE] = true;
    }

    function setTreasury(address next) external onlyOwner {
        if (next == address(0)) revert InvalidTreasury();
        emit TreasurySet(treasury, next);
        treasury = next;
    }

    function setFeeEnabled(FeeKind kind, bool enabled) external onlyOwner {
        feeEnabled[kind] = enabled;
        emit FeeKindSet(kind, enabled);
    }

    /// @notice Record a fee invoice against a deal. Agent-gated (typically automation key).
    function recordInvoice(
        bytes32 dealId,
        FeeKind kind,
        address payer,
        address token,
        uint256 amount
    ) external onlyAgent returns (uint256 id) {
        if (!feeEnabled[kind]) revert KindDisabled();
        _invoices.push(Invoice({
            dealId: dealId,
            kind: kind,
            payer: payer,
            token: token,
            amount: amount,
            timestamp: uint64(block.timestamp),
            paid: false
        }));
        id = _invoices.length - 1;
        emit InvoiceRecorded(id, dealId, kind, amount);
    }

    /// @notice Collect a recorded invoice — pulls from payer and forwards to treasury in a single tx.
    /// @dev    Payer must approve this contract for `amount` beforehand. This contract holds zero balance
    ///         between the transferFrom and the transfer — non-custodial by construction.
    function collect(uint256 id) external onlyAgent {
        if (id >= _invoices.length) revert NoInvoice();
        Invoice storage inv = _invoices[id];
        if (inv.paid) revert AlreadyPaid();
        inv.paid = true;

        // Pull from payer
        bool ok1 = IERC20(inv.token).transferFrom(inv.payer, address(this), inv.amount);
        if (!ok1) revert TransferFailed();
        // Forward to treasury (no long-term balance retained)
        bool ok2 = IERC20(inv.token).transfer(treasury, inv.amount);
        if (!ok2) revert TransferFailed();

        emit InvoicePaid(id, inv.token, inv.amount);
    }

    function invoiceCount() external view returns (uint256) {
        return _invoices.length;
    }

    function getInvoice(uint256 id) external view returns (Invoice memory) {
        if (id >= _invoices.length) revert NoInvoice();
        return _invoices[id];
    }
}
