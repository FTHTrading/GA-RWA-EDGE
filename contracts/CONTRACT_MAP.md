# LD Capital / LDX — Smart Contract & Funding-Path Map

**Scope.** LD Capital is the **issuance / funding arm** — it originates deals, tokenizes the
claim, and moves capital in and out. **LDX** is the **compliant exchange & settlement layer**
that sits across every asset LD Capital issues — secondary trading, atomic settlement,
distribution routing, and the ATS bridge. One shared compliance core underpins both, so a KYC'd
investor is verified once and can hold or trade any LD instrument.

**Invariant (non-negotiable, enforced in code):** *compliance is a gate before value moves.*
Every transfer, mint, distribution, and draw reverts unless identity + compliance + (where value
moves) the AML/Travel-Rule gate pass first. Integer minor units only. Non-custodial: the issuer can
freeze and recover on an audit trail, but never silently moves investor funds.

Status legend: **✅ BUILT** = written and compiled this cycle (solc 0.8.36, in this repo).
**◻ TO BUILD** = specified here, owned by the named skill, sequenced in the roadmap.

---

## Layer 0 — Shared compliance core (every funding path depends on this)

| Contract | Status | Role | Owning skill |
|---|---|---|---|
| `Roles` | ✅ BUILT | Owner (governance) / Agent (ops) separation | — |
| `ECDSALib` | ✅ BUILT | Canonical-only ECDSA (rejects high-s / bad v) | oracle-attestation-framework |
| `IdentityRegistry` | ✅ BUILT | `isVerified` — KYC/AML/accredited topic gate, country binding | erc3643-tokenomics |
| `ModularCompliance` | ✅ BUILT | Binds modules; `canTransfer` = AND of all modules | erc3643-tokenomics |
| `Rule144LockupModule` | ✅ BUILT | Per-lot holding-period lockup (Reg D/S, tacking) | erc3643-tokenomics |
| `CountryRestrictModule` | ✅ BUILT | ISO-3166 allowlist (Reg S offshore, sanctions exclude) | erc3643-tokenomics |
| `MaxHoldersModule` | ✅ BUILT | Beneficial-owner cap (Reg D 2000 / 3(c) limits) | erc3643-tokenomics |
| `LDSecurityToken` | ✅ BUILT | ERC-3643 gated security token (the LD instrument) | erc3643-tokenomics |
| `AttestationVerifier` | ✅ BUILT | EIP-712 m-of-n oracle primitive (reserve, meter, price) | oracle-attestation-framework |
| `ReserveProofAnchor` | ✅ BUILT | Append-only reserve/collateral proof (quorum-valued) | (reserve proof) |
| `AMLTravelRuleGate` | ✅ BUILT | OFAC/SDN screen + Travel-Rule + monitoring gate; wired into token + tranche claims | aml-kyc-travel-rule |
| `CustodyAdapter` | ✅ BUILT | 4-eyes m-of-n + velocity + delay boundary for agent ops | bitgo-vault-automation |
| `DealRegistry` | ✅ BUILT | Per-deal index (token/waterfall/reserve/status); one KYC, many instruments | erc3643-tokenomics |
| `LDTimelock` | ✅ BUILT | Delayed governance owner (never a single EOA) | smart-contract-security-audit |
| `ReentrancyGuard` | ✅ BUILT | Defense-in-depth on USDC-moving paths | smart-contract-security-audit |

---

## Funding paths — LD Capital

Each path is a way capital comes **in** and is serviced **out**. The contracts listed beyond the
shared core are what that path adds.

### Path 1 — CMBS / CRE securitization  ✅ *first path built (M Helen $29.1M live reference)*
**Capital in:** tranche sales to Reg D 506(c) / Reg S investors. **Out:** deterministic waterfall.

| Contract | Status | Role |
|---|---|---|
| `CMBSWaterfall` | ✅ BUILT | Fee → sequential interest → principal (sequential/turbo) → residual |
| `TrancheToken` | ✅ BUILT | Compliance-gated tranche claim, dust-free magnified USDC distributor |
| `DSCRTrigger` | ✅ BUILT | DSCR/LTV covenant state machine (cash-trap 1.20x, turbo 1.10x, hysteresis) |
| `ConstructionDrawEscrow` + `LienWaiver` | ◻ TO BUILD | Draw release on drone/inspector attestation, atomic draw-for-waiver | 
| Zero-Coupon Land Bond | ✅ (mode) | `CMBSWaterfall.Kind.ACCRETION` — accretes to par, first-loss |

*Construction-draw contracts owned by `construction-draw-escrow` (imports `AttestationVerifier`).*

### Path 2 — Private credit / direct lending
**Capital in:** USDC pool deposits. **Out:** loans; interest accrual; liquidation.

| Contract | Status | Role |
|---|---|---|
| `CreditVault` (ERC-4626) | ◻ TO BUILD | Deposit/withdraw, share accounting, senior/junior |
| `LoanAgreement` + `InterestAccrual` | ◻ TO BUILD | Draw, schedule, accrual |
| `LiquidationEngine` | ◻ TO BUILD | Collateral seize on default |
| XRPL: lending Hook + Single Asset Vault + MPT | ◻ TO BUILD | Non-EVM on-ledger lending (xrplloans.unykorn.org) |

*EVM owned by erc3643-tokenomics + smart-contract-security-audit; XRPL by `xrpl-lending-hooks`.*

### Path 3 — RWA tokenization (real estate, mining, commodities)
**Capital in:** primary token sale. **Out:** NAV appreciation / income (→ Path 4).

| Contract | Status | Role |
|---|---|---|
| `LDSecurityToken` | ✅ BUILT | The asset token (reused) |
| `ReserveProofAnchor` + `AttestationVerifier` | ✅ BUILT | Reserve/appraisal proof, quorum-valued |
| `NAVOracle` / `AppraisalRegistry` | ◻ TO BUILD | On-chain NAV from appraisal + liabilities |

*Off-chain gate: `forensic-osint-audit` on asset/counterparty before mint.*

### Path 4 — REIT / income distribution
**Capital in:** REIT share sales. **Out:** NOI-driven pro-rata dividends, 90% test.

| Contract | Status | Role |
|---|---|---|
| `REITDividendDistributor` | ◻ TO BUILD | NOI calc, 90% distribution test, snapshot, magnified per-share |
| (distributor primitive) | ✅ BUILT | `TrancheToken`'s magnified accumulator is the reusable core |

*Owned by `reit-dividend-engine`.*

### Path 5 — Energy: SREC + tax-equity ITC flips
**Capital in:** ITC tax-equity investor + SREC revenue. **Out:** green-yield distribution.

| Contract | Status | Role |
|---|---|---|
| `SRECMinter` | ◻ TO BUILD | Meter attestation → 1 SREC / MWh, idempotent, registry reconcile |
| `TaxEquityFlip` | ◻ TO BUILD | 99/1 → 5/95 flip on after-tax IRR, ITC allocation ledger |
| `GreenYieldDistributor` | ◻ TO BUILD | Yield routing to holders |
| `AttestationVerifier` | ✅ BUILT | The meter-reading primitive (reused) |

*Owned by `srec-minting-telemetry` + `tax-equity-itc-flips`.*

### Path 6 — MTN program (OPTKAS $500M framework)
**Capital in:** note sales. **Out:** coupons + redemption.

| Contract | Status | Role |
|---|---|---|
| `NoteToken` (ERC-3643 debt) | ◻ TO BUILD | Permissioned note instrument |
| `CouponScheduler` + `RedemptionEngine` | ◻ TO BUILD | Coupon accrual, maturity redemption |
| `MTNProgramRegistry` | ◻ TO BUILD | Series/tranche registry under the program |

### Path 7 — Neobank / fiat settlement rails (MSB clearing)
**Capital in/out:** ACH / Fedwire / SWIFT ↔ on-chain, via licensed partner (non-custodial).

| Contract | Status | Role |
|---|---|---|
| `SettlementReconciler` | ◻ TO BUILD | Match bank settlement ↔ on-chain deposit |
| `VirtualIBANRegistry` | ◻ TO BUILD | Synthetic IBAN ↔ tenant mapping |
| `AMLTravelRuleGate` | ◻ TO BUILD | Screen every fiat↔chain hop |

*Owned by `neobank-msb-clearing` + `aml-kyc-travel-rule`.*

---

## LDX — exchange & settlement layer (spans all paths)

| Contract | Status | Role |
|---|---|---|
| `LDXAtomicSettlement` (DvP) | ◻ TO BUILD | Atomic delivery-vs-payment; token + USDC settle in one tx or revert |
| `LDXRfqSettlement` | ◻ TO BUILD | Off-chain quote, on-chain compliant settle (both sides verified) |
| `ATSBridge` (Securitize) | ◻ TO BUILD | Restriction carriage + transfer-agent cap-table sync |
| `LDXIndexToken` | ◻ TO BUILD | ERC-3643 basket wrapping multiple LD assets |
| `CouponDividendRouter` | ◻ TO BUILD | Routes distributions from every path to current holders |
| `LDXFeeController` | ◻ TO BUILD | Explicit bps fees (Loop Engine monetization), no opaque spread |
| (transfer gate) | ✅ BUILT | `LDSecurityToken`/`TrancheToken` gates enforce compliance on every trade |

Every LDX trade re-runs the **same** `isVerified` + `canTransfer` + AML gate — there is no
secondary-market bypass. This is the property that keeps restricted securities restricted after
they start trading.

---

## Deploy order (dependency DAG)

```
Roles / ECDSALib (libs, inlined)
        │
        ▼
IdentityRegistry ──► ModularCompliance ──► add [Rule144, Country, MaxHolders]
        │                    │
        │                    ▼
        │            LDSecurityToken ──► compliance.bindToken(token)
        │                    │           modules.bindCompliance(token, compliance)
        │                    │
AttestationVerifier ──► ReserveProofAnchor
        │
        ▼
[per deal]  DSCRTrigger ──► TrancheToken×N ──► CMBSWaterfall
                                   │                 │
                                   └── setDistributor(waterfall)
                                                     └── addTranche(...) in priority order
        │
        ▼
AMLTravelRuleGate ──► CustodyAdapter ──► LDX settlement layer
```

Owner = multisig/timelock at every node. Agents = automation keys behind CustodyAdapter velocity +
4-eyes. No node grants an admin fund-withdrawal path.

---

## Built this cycle (compiled, deployable)

16 contracts compile clean under solc 0.8.36 with zero errors. The M Helen waterfall reconciles
bit-identically to the Python reference model (`reference/waterfall_model.py`) with exact
conservation (fee + interest + principal + residual = payment; no dust in sequential or turbo mode).

**Not yet done and required before any mainnet value:** `smart-contract-security-audit` full pass,
the `AMLTravelRuleGate` + `CustodyAdapter`, securities-counsel sign-off on Rule 144 lockup/tacking,
and the legal SPV/security-agreement package that makes `ReserveProofAnchor` reference enforceable
collateral rather than notarization.

## Build roadmap (sequenced)

1. **Core hardening** — `AMLTravelRuleGate`, `CustodyAdapter`, `Timelock/Governor`, `DealRegistry`; then `smart-contract-security-audit` on Layer 0 + CMBS.
2. **Path 1 completion** — `ConstructionDrawEscrow` + `LienWaiver` for draw-based CRE; deploy M Helen to Base testnet; full test suite.
3. **Path 4 + Path 3** — `REITDividendDistributor`, `NAVOracle` (fastest revenue: income distribution on tokenized RE).
4. **Path 5** — `SRECMinter` + `TaxEquityFlip` (energy is the largest portfolio vertical).
5. **Path 2 + Path 6** — private credit vaults (EVM + XRPL) and the MTN program.
6. **LDX** — atomic settlement, ATS bridge, index token, distribution router.
