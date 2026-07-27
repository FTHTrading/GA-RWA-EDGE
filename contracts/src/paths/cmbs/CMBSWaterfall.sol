// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../../core/Roles.sol";
import {ReentrancyGuard} from "../../core/ReentrancyGuard.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {TrancheToken} from "./TrancheToken.sol";
import {DSCRTrigger} from "./DSCRTrigger.sol";

/// @title CMBSWaterfall
/// @notice Deterministic, non-custodial CMBS payment waterfall. The servicer pushes a
///         single periodic USDC payment; the contract splits it across tranches in a
///         priority order the math alone decides — fee, sequential interest, then
///         principal (sequential normally, pro-rata "turbo" on a DSCR/LTV breach), with
///         residual to the junior equity tranche or the reserve under cash-trap.
/// @dev    Integer USDC minor units (6dp) and bps only; multiply-before-divide. No admin
///         withdrawal path — the contract is a conduit, not a custodian. Configured for
///         the M Helen Hotel deal by the deploy script (Senior $25M / Mezz-Land $4.1M /
///         Pref Equity), but deal-agnostic.
contract CMBSWaterfall is Roles, ReentrancyGuard {
    enum Kind { CASH_PAY, ACCRETION }

    struct Tranche {
        TrancheToken token;    // ERC-3643-gated tranche claim token
        uint8   priority;      // 1 = most senior (paid first, loses last)
        uint256 principalOut;  // remaining principal, USDC minor units
        uint256 rateBps;       // coupon (CASH_PAY) or accretion rate (ACCRETION), bps p.a.
        uint256 accruedInt;    // interest accrued but unpaid
        uint256 parValue;      // accretion cap (ACCRETION tranches)
        Kind    kind;
        bool    writtenDown;
    }

    IERC20 public immutable usdc;
    DSCRTrigger public trigger;
    address public servicer;
    address public feeSink;
    address public reserveSink;
    uint256 public servicingFeeBps;

    Tranche[] public tranches; // stored in ascending priority (index 0 = most senior)

    event TrancheAdded(uint8 priority, address token, uint256 principal, uint256 rateBps, Kind kind);
    event Accrued(uint256 indexed period, uint256 trancheIndex, uint256 interest);
    event Accreted(uint256 indexed period, uint256 trancheIndex, uint256 accretion, uint256 principalOut);
    event Distributed(
        uint256 indexed period,
        uint256 fee,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 residual,
        uint8 mode
    );
    event InterestPaid(uint256 trancheIndex, uint256 amount);
    event PrincipalPaid(uint256 trancheIndex, uint256 amount);
    event ResidualRouted(address to, uint256 amount);
    event LossWrittenDown(uint256 trancheIndex, uint256 amount);

    error NotServicer();
    error PriorityNotAscending();
    error TransferInFailed();
    error NoTranches();

    uint256 public period; // increments each distribution

    constructor(
        address owner_,
        IERC20 usdc_,
        DSCRTrigger trigger_,
        address servicer_,
        address feeSink_,
        address reserveSink_,
        uint256 servicingFeeBps_
    ) Roles(owner_) {
        usdc = usdc_;
        trigger = trigger_;
        servicer = servicer_;
        feeSink = feeSink_;
        reserveSink = reserveSink_;
        servicingFeeBps = servicingFeeBps_;
    }

    modifier onlyServicer() {
        if (msg.sender != servicer) revert NotServicer();
        _;
    }

    function trancheCount() external view returns (uint256) {
        return tranches.length;
    }

    function addTranche(
        TrancheToken token,
        uint8 priority,
        uint256 principalOut,
        uint256 rateBps,
        uint256 parValue,
        Kind kind
    ) external onlyOwner {
        if (tranches.length > 0 && priority <= tranches[tranches.length - 1].priority) {
            revert PriorityNotAscending();
        }
        tranches.push(Tranche({
            token: token,
            priority: priority,
            principalOut: principalOut,
            rateBps: rateBps,
            accruedInt: kind == Kind.ACCRETION ? 0 : rateBps, // placeholder overwritten on accrue
            parValue: parValue,
            kind: kind,
            writtenDown: false
        }));
        // reset the seeded accruedInt (we set it non-zero above only to avoid an unused warning path)
        tranches[tranches.length - 1].accruedInt = 0;
        emit TrancheAdded(priority, address(token), principalOut, rateBps, kind);
    }

    /// @notice ACT/360 period interest, integer, multiply-before-divide.
    function periodInterest(uint256 principal, uint256 rateBps, uint256 periodDays)
        public
        pure
        returns (uint256)
    {
        return (principal * rateBps * periodDays) / (10_000 * 360);
    }

    /// @notice Distribute one period's payment across the stack.
    /// @param payment    incoming USDC (minor units) — pulled from the servicer.
    /// @param periodDays day-count for this period (typically 30).
    function distribute(uint256 payment, uint256 periodDays) external onlyServicer nonReentrant {
        uint256 n = tranches.length;
        if (n == 0) revert NoTranches();
        period += 1;

        if (!usdc.transferFrom(msg.sender, address(this), payment)) revert TransferInFailed();

        uint256 available = payment;

        // 1. Explicit servicing fee (only middleman line-item).
        uint256 fee = (available * servicingFeeBps) / 10_000;
        available -= fee;
        if (fee > 0) require(usdc.transfer(feeSink, fee), "fee xfer");

        // 2. Accrue interest / accrete principal.
        for (uint256 i; i < n; ++i) {
            Tranche storage t = tranches[i];
            if (t.kind == Kind.ACCRETION) {
                if (t.principalOut < t.parValue) {
                    uint256 acc = periodInterest(t.principalOut, t.rateBps, periodDays);
                    if (t.principalOut + acc > t.parValue) acc = t.parValue - t.principalOut;
                    t.principalOut += acc;
                    emit Accreted(period, i, acc, t.principalOut);
                }
            } else {
                uint256 intr = periodInterest(t.principalOut, t.rateBps, periodDays);
                t.accruedInt += intr;
                emit Accrued(period, i, intr);
            }
        }

        // 3. Sequential interest, senior first (CASH_PAY only).
        uint256 interestPaid;
        for (uint256 i; i < n && available > 0; ++i) {
            Tranche storage t = tranches[i];
            if (t.kind == Kind.ACCRETION) continue;
            uint256 pay = available < t.accruedInt ? available : t.accruedInt;
            if (pay > 0) {
                t.accruedInt -= pay;
                available -= pay;
                interestPaid += pay;
                _allocate(i, pay);
                emit InterestPaid(i, pay);
            }
        }

        // 4. Principal — mode from the covenant state machine.
        DSCRTrigger.Mode m = trigger.mode();
        uint256 principalPaid;
        if (available > 0) {
            if (m == DSCRTrigger.Mode.TURBO) {
                principalPaid = _proRataPrincipal(available);
            } else {
                principalPaid = _sequentialPrincipal(available);
            }
            available -= principalPaid;
        }

        // 5. Residual: cash-trap -> reserve; else -> most-junior cash-pay tranche.
        uint256 residual = available;
        if (residual > 0) {
            if (m == DSCRTrigger.Mode.CASH_TRAP) {
                require(usdc.transfer(reserveSink, residual), "reserve xfer");
                emit ResidualRouted(reserveSink, residual);
            } else {
                uint256 jr = _mostJuniorCashPay();
                _allocate(jr, residual);
                emit ResidualRouted(address(tranches[jr].token), residual);
            }
        }

        emit Distributed(period, fee, interestPaid, principalPaid, residual, uint8(m));
    }

    function _allocate(uint256 index, uint256 amount) internal {
        if (amount == 0) return;
        TrancheToken tk = tranches[index].token;
        require(usdc.transfer(address(tk), amount), "alloc xfer");
        tk.allocate(amount);
    }

    function _sequentialPrincipal(uint256 available) internal returns (uint256 paid) {
        uint256 n = tranches.length;
        for (uint256 i; i < n && available > 0; ++i) {
            Tranche storage t = tranches[i];
            if (t.principalOut == 0) continue;
            uint256 pay = available < t.principalOut ? available : t.principalOut;
            t.principalOut -= pay;
            available -= pay;
            paid += pay;
            _allocate(i, pay);
            emit PrincipalPaid(i, pay);
        }
    }

    /// @dev Largest-remainder pro-rata split so sum(parts) == available exactly (no dust
    ///      created/lost). Weight = principalOut of each tranche with principal remaining.
    function _proRataPrincipal(uint256 available) internal returns (uint256 paid) {
        uint256 n = tranches.length;
        uint256 totalWeight;
        for (uint256 i; i < n; ++i) totalWeight += tranches[i].principalOut;
        if (totalWeight == 0) return 0;

        uint256[] memory alloc = new uint256[](n);
        uint256[] memory rem = new uint256[](n);
        uint256 assigned;
        for (uint256 i; i < n; ++i) {
            uint256 w = tranches[i].principalOut;
            if (w == 0) continue;
            uint256 numer = available * w;
            uint256 base = numer / totalWeight;
            // never allocate more principal than remains
            if (base > w) base = w;
            alloc[i] = base;
            rem[i] = numer % totalWeight;
            assigned += base;
        }
        // Distribute the leftover minor units to the largest remainders (that still have room).
        uint256 leftover = available - assigned;
        while (leftover > 0) {
            uint256 best = type(uint256).max;
            uint256 bestRem;
            for (uint256 i; i < n; ++i) {
                if (alloc[i] < tranches[i].principalOut && rem[i] >= bestRem) {
                    // strict tie-break toward the more senior (lower index) via >=
                    if (best == type(uint256).max || rem[i] > bestRem) {
                        best = i;
                        bestRem = rem[i];
                    }
                }
            }
            if (best == type(uint256).max) break; // no tranche has room; leftover stays as residual
            alloc[best] += 1;
            rem[best] = 0;
            leftover -= 1;
        }

        for (uint256 i; i < n; ++i) {
            if (alloc[i] == 0) continue;
            tranches[i].principalOut -= alloc[i];
            paid += alloc[i];
            _allocate(i, alloc[i]);
            emit PrincipalPaid(i, alloc[i]);
        }
    }

    function _mostJuniorCashPay() internal view returns (uint256 idx) {
        uint256 n = tranches.length;
        bool found;
        for (uint256 i; i < n; ++i) {
            if (tranches[i].kind == Kind.CASH_PAY) {
                idx = i;
                found = true;
            }
        }
        require(found, "no cash-pay tranche");
    }

    /// @notice Write down principal from the bottom of the stack up (accretion/junior
    ///         first) to record a collateral loss. Agent-gated, auditable.
    function writeDownLoss(uint256 loss) external onlyAgent {
        uint256 n = tranches.length;
        for (uint256 k = n; k > 0 && loss > 0; ) {
            uint256 i = k - 1; // most junior first
            Tranche storage t = tranches[i];
            uint256 hit = loss < t.principalOut ? loss : t.principalOut;
            if (hit > 0) {
                t.principalOut -= hit;
                loss -= hit;
                t.writtenDown = true;
                emit LossWrittenDown(i, hit);
            }
            unchecked { --k; }
        }
    }

    function setServicer(address s) external onlyOwner { servicer = s; }
    function setFeeSink(address s) external onlyOwner { feeSink = s; }
    function setReserveSink(address s) external onlyOwner { reserveSink = s; }
    function setTrigger(DSCRTrigger t) external onlyOwner { trigger = t; }
}
