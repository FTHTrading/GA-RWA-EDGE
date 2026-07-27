// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.36;

import {Roles} from "../../core/Roles.sol";

/// @title DSCRTrigger
/// @notice Covenant state machine for a CMBS deal. Tracks DSCR (bps) and LTV (bps) and
///         derives the principal repayment mode: NORMAL (sequential), CASH_TRAP (divert
///         equity residual to reserve), or TURBO (pro-rata acceleration of senior
///         principal). Requires N consecutive breaches before flipping (hysteresis) and a
///         cure margin before flipping back — no flapping.
/// @dev    dscrBps / ltvBps are pushed by an agent/oracle. Thresholds are deal config.
contract DSCRTrigger is Roles {
    enum Mode { NORMAL, CASH_TRAP, TURBO }

    // Deal thresholds (bps). Defaults per skill; tune per deal.
    uint256 public cashTrapDscrBps = 12_000; // 1.20x
    uint256 public turboDscrBps = 11_000;     // 1.10x
    uint256 public ltvCovenantBps = 7_500;    // 0.75x
    uint256 public triggerConfirm = 2;        // consecutive breaches to flip
    uint256 public cureConfirm = 2;           // consecutive cures to flip back

    uint256 public dscrBps;
    uint256 public ltvBps;
    Mode public mode;

    uint256 public breachStreak; // consecutive periods below turbo threshold
    uint256 public trapStreak;   // consecutive periods below cash-trap threshold
    uint256 public cureStreak;   // consecutive healthy periods

    event ThresholdsSet(uint256 cashTrap, uint256 turbo, uint256 ltv, uint256 confirm, uint256 cure);
    event CovenantUpdated(uint256 dscrBps, uint256 ltvBps, Mode mode);
    event ModeChanged(Mode mode);

    constructor(address owner_) Roles(owner_) {}

    function setThresholds(
        uint256 cashTrap,
        uint256 turbo,
        uint256 ltv,
        uint256 confirm,
        uint256 cure
    ) external onlyOwner {
        require(turbo <= cashTrap, "turbo<=cashTrap");
        require(confirm > 0 && cure > 0, "confirm>0");
        cashTrapDscrBps = cashTrap;
        turboDscrBps = turbo;
        ltvCovenantBps = ltv;
        triggerConfirm = confirm;
        cureConfirm = cure;
        emit ThresholdsSet(cashTrap, turbo, ltv, confirm, cure);
    }

    /// @notice Compute DSCR from raw period figures (integer, kept in bps).
    function dscrFrom(uint256 noiPeriod, uint256 debtServicePeriod) public pure returns (uint256) {
        require(debtServicePeriod > 0, "zero debt service");
        return (noiPeriod * 10_000) / debtServicePeriod;
    }

    /// @notice Push a new covenant reading and advance the state machine.
    function update(uint256 dscrBps_, uint256 ltvBps_) external onlyAgent {
        dscrBps = dscrBps_;
        ltvBps = ltvBps_;

        bool ltvBreach = ltvBps_ > ltvCovenantBps;
        Mode prev = mode;

        if (dscrBps_ < turboDscrBps || ltvBreach) {
            breachStreak += 1;
            trapStreak += 1;
            cureStreak = 0;
            if (breachStreak >= triggerConfirm) mode = Mode.TURBO;
            else if (trapStreak >= triggerConfirm) mode = Mode.CASH_TRAP;
        } else if (dscrBps_ < cashTrapDscrBps) {
            trapStreak += 1;
            breachStreak = 0;
            cureStreak = 0;
            if (trapStreak >= triggerConfirm) mode = Mode.CASH_TRAP;
        } else {
            cureStreak += 1;
            if (cureStreak >= cureConfirm) {
                mode = Mode.NORMAL;
                breachStreak = 0;
                trapStreak = 0;
            }
        }

        emit CovenantUpdated(dscrBps_, ltvBps_, mode);
        if (mode != prev) emit ModeChanged(mode);
    }

    function isHealthy() external view returns (bool) {
        return mode == Mode.NORMAL;
    }
}
