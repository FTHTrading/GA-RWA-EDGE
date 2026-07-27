// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {ModuleBase} from "./ModuleBase.sol";

/// @title Rule144LockupModule
/// @notice Enforces a per-acquisition holding period (Rule 144 restricted-securities
///         lockup) at the contract level. Each acquired lot records its unlock time;
///         a transfer can only spend tokens whose lot has matured.
/// @dev    LEGAL NOTE: the lockup timestamp here REFLECTS a determination made off-chain
///         by counsel/transfer agent — it does not itself make a Rule 144 holding period
///         legally valid (esp. tacking through a burn-and-reissue migration). The
///         `lockSeconds` and any tacked `originAcquired` MUST be set from counsel's
///         instruction, not assumed. See map: securities-counsel gate precedes minting.
contract Rule144LockupModule is ModuleBase {
    // token => holding period seconds (e.g. 180 days Reg D, 365 days for non-reporting)
    mapping(address => uint256) public lockSeconds;

    struct Lot {
        uint256 amount;   // remaining amount in this lot
        uint64  unlockAt; // timestamp after which this lot is transferable
    }

    // token => holder => FIFO queue of lots
    mapping(address => mapping(address => Lot[])) private _lots;
    // token => holder => head index into the lot queue (consumed lots skipped)
    mapping(address => mapping(address => uint256)) private _head;

    event LockSet(address indexed token, uint256 lockSeconds);
    event LotCreated(address indexed token, address indexed holder, uint256 amount, uint64 unlockAt);

    constructor(address owner_) ModuleBase(owner_) {}

    function setLock(address token, uint256 lockSeconds_) external onlyOwner {
        lockSeconds[token] = lockSeconds_;
        emit LockSet(token, lockSeconds_);
    }

    /// @notice Amount currently transferable (lots whose unlockAt <= now).
    function unlockedBalance(address token, address holder) public view returns (uint256 free) {
        Lot[] storage lots = _lots[token][holder];
        uint256 n = lots.length;
        for (uint256 i = _head[token][holder]; i < n; ++i) {
            if (lots[i].unlockAt <= block.timestamp) free += lots[i].amount;
        }
    }

    function moduleCheck(address from, address, uint256 amount, address token)
        external
        view
        override
        returns (bool)
    {
        if (amount == 0) return true;
        // Mint path (from == 0) is authorized elsewhere; lockup only constrains spends.
        if (from == address(0)) return true;
        return unlockedBalance(token, from) >= amount;
    }

    // ---- state hooks ----

    /// @dev New tokens to `to` start a lockup lot dated from now + lockSeconds.
    function moduleMintAction(address to, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        _createLot(token, to, amount, uint64(block.timestamp) + uint64(lockSeconds[token]));
    }

    /// @dev Transfers consume unlocked lots FIFO from `from`; the received amount opens a
    ///      fresh lot for `to` (secondary acquirer inherits a new holding period).
    function moduleTransferAction(address from, address to, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        _consume(token, from, amount);
        _createLot(token, to, amount, uint64(block.timestamp) + uint64(lockSeconds[token]));
    }

    function moduleBurnAction(address from, uint256 amount, address token)
        external
        override
        onlyCompliance(token)
    {
        _consume(token, from, amount);
    }

    /// @notice Governance-set opening lot with an explicit tacked unlock time (migration
    ///         carry-forward of an ORIGINAL acquisition date per counsel instruction).
    function seedLot(address token, address holder, uint256 amount, uint64 unlockAt)
        external
        onlyOwner
    {
        _createLot(token, holder, amount, unlockAt);
    }

    function _createLot(address token, address holder, uint256 amount, uint64 unlockAt) internal {
        if (amount == 0) return;
        _lots[token][holder].push(Lot({amount: amount, unlockAt: unlockAt}));
        emit LotCreated(token, holder, amount, unlockAt);
    }

    /// @dev Consume `amount` from the holder's lots FIFO. Prefers matured lots first so a
    ///      spend never fails when enough is unlocked, then draws remaining from the queue.
    function _consume(address token, address holder, uint256 amount) internal {
        Lot[] storage lots = _lots[token][holder];
        uint256 n = lots.length;
        uint256 i = _head[token][holder];
        // First pass: matured lots.
        for (; i < n && amount > 0; ) {
            Lot storage lot = lots[i];
            if (lot.amount == 0) { unchecked { ++i; } continue; }
            if (lot.unlockAt <= block.timestamp) {
                uint256 take = lot.amount < amount ? lot.amount : amount;
                lot.amount -= take;
                amount -= take;
            }
            if (lot.amount == 0) { unchecked { ++i; } } else { break; }
        }
        _head[token][holder] = i;
        // Second pass (only reached on burn of still-locked tokens): draw any remaining.
        for (uint256 k = _head[token][holder]; k < n && amount > 0; ++k) {
            Lot storage lot = lots[k];
            if (lot.amount == 0) continue;
            uint256 take = lot.amount < amount ? lot.amount : amount;
            lot.amount -= take;
            amount -= take;
        }
        require(amount == 0, "lockup: insufficient lots");
    }
}
