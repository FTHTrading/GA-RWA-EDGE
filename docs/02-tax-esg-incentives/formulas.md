# Tax, ESG & Incentive Formulas Reference

**(Post-OBBBA, July 2026 · GA edge-DC RWA stack)**

Working formulas and metrics for underwriting models, `CMBSWaterfall.sol` priority / residual logic, `ReserveProofAnchor` attestation schemas, investor PPM quantitative sections, and tax-equity term-sheet negotiations.

Every formula here is used to size the capital stack, configure the waterfall, or populate investor materials. All numbers reflect current OBBBA / post-July-4-2025 law.

---

## 1. Opportunity Zone / QROF (OZ 2.0)

### 1.1 Deferred gain recognition

```text
Deferred Gain Recognized = Original Deferred Gain − Basis Step-Up
```

### 1.2 Basis step-up (after continuous 5-year hold)

```text
Standard QOF: Step-Up = 10% × Original Deferred Gain
QROF (Rural): Step-Up = 30% × Original Deferred Gain
```

### 1.3 Taxable amount at year 5 (or earlier inclusion event)

```text
Taxable Deferred Gain = Original Deferred Gain × (1 − Step-Up%)
```

### 1.4 Federal tax savings from step-up

```text
Tax Savings ≈ Step-Up Amount × 23.8%
```

_23.8% = 20% federal LTCG rate + 3.8% Net Investment Income Tax (NIIT). State tax varies by jurisdiction._

### 1.5 Worked example — $10M deferred gain into QROF

- Step-Up = 30% × $10,000,000 = **$3,000,000**
- Taxable amount at year 5 = $10,000,000 − $3,000,000 = **$7,000,000**
- Federal tax on $7M @ 23.8% = ~$1,666,000
- Federal tax saved vs no step-up = **~$714,000**
- QROF advantage vs standard QOF (10% step-up) = **~$476,000**

### 1.6 10-year exclusion rule

If held ≥ 10 years, post-investment appreciation is generally excluded via a basis step-up to Fair Market Value on sale, subject to the OZ 2.0 30-year FMV election rules. The 5-year 30% step-up already locked in does not reverse.

### 1.7 Substantial improvement test (rural)

```text
Improvement Spend ≥ 50% × Adjusted Basis of Building (excluding land)
```

Effective July 4, 2025 for rural QOZ property. Non-rural remains 100% threshold.

### 1.8 Statutory rural definition (critical)

Per IRC §1400Z-2 as amended by OBBBA:

> A **rural area** = any area other than **(i)** a city or town with population > 50,000, **and** **(ii)** any Census-defined urbanized area contiguous and adjacent to such a city or town.

Both prongs must clear. Per-tract test, not per-county. Verify each candidate tract against the certified 2027 QOZ map and the Census urbanized-area boundary for Atlanta / Marietta before signing any option.

---

## 2. Investment Tax Credit §48E / Clean Electricity (HISTORICAL — CUTOFF MISSED)

> ⚠️ **Solar / Wind ITC no longer available for new projects.** The begin-construction safe harbor lapsed **July 4, 2026**. This section is retained as historical reference and for storage-only projects. **Do not model solar / wind ITC into any live capital stack.**

### 2.1 Deployment rules that still apply

- **Solar / wind sprint window:** ~~begin construction by July 4, 2026~~ **CUTOFF PASSED** — no longer available for new solar / wind builds
- **Energy storage (standalone, no paired solar):** full 30% baseline rate through **2033** — still available
- **Base rate:** 30% of eligible basis · + adders up to +10-20% (domestic content · energy community) — applies to remaining eligible technologies (storage, geothermal, nuclear PTC)

### 2.2 ITC amount

```text
ITC = Eligible Cost Basis × Credit Percentage (normally 30%)
```

### 2.3 Eligible basis

**Included:** solar modules · inverters · racking / mounting · balance-of-system electrical hardware · direct site-interconnection costs.

**Excluded / capped:** land acquisitions · general site prep · soft costs (limited) · roads · fencing · permits (case-by-case).

### 2.4 Transferability / direct pay (per IRC §6418, OBBBA-preserved)

Credits can be monetized via **direct transfer (sale for cash)** or claimed as **direct pay** by eligible tax-exempt entities. FEOC restrictions from July 4, 2025 forward apply.

### 2.5 Impact on capital stack

```text
Tax Equity Investment ≈ 1.0× to 1.3× ITC Amount
```

Investor commits above 1.0× to capture MACRS + reach target after-tax IRR.

---

## 3. Tax Equity Partnership Flip

### 3.1 Allocation profile

| Stage | Tax equity share | Sponsor / SPE share |
|---|---|---|
| Pre-flip | 99% of tax benefits (ITC + MACRS) | 1% |
| Post-flip | 5% | 95% |

### 3.2 Sizing

Sized so investor achieves defined **after-tax IRR** — current market ~7.5-9.5% for investment-grade credit profiles, higher for merchant / weaker credits.

```text
Tax Equity $ ≈ 1.1× to 1.3× ITC Amount
```

### 3.3 Flip triggers

- **Yield-based:** triggers when tax equity reaches target after-tax IRR
- **Date-based:** fixed calendar date — typically year 5-7

### 3.4 Depreciation allocation

99% pre-flip to tax equity partner. Solar and immersion-cooling electrical equipment generally qualify for **5-year MACRS** plus **100% bonus depreciation** (permanent for property placed in service after Jan 19, 2025).

---

## 4. MACRS Depreciation + 100% Bonus

### 4.1 Recovery periods

| Item | Rule |
|---|---|
| Bonus depreciation | **100% permanent** post-Jan 19, 2025 |
| Solar / clean energy | 5-year (with OBBBA modifications for post-Dec 31, 2024 construction starts) |
| Data-center IT equipment | 5-year — servers, GPUs, networking, immersion systems |
| UPS · batteries · power conditioning | Often 7-year |
| Land improvements | 15-year |
| Building / structural | 39-year (no bonus) |
| Convention | Half-year (default) unless mid-quarter applies |

### 4.2 Standard 5-year MACRS table

| Recovery year | % of basis |
|---|---|
| 1 | 20.00% |
| 2 | 32.00% |
| 3 | 19.20% |
| 4 | 11.52% |
| 5 | 11.52% |
| 6 | 5.76% |
| **Total** | **100.00%** |

Due to half-year convention, a "5-year" asset is recovered over six tax years.

### 4.3 CRITICAL — ITC basis reduction

When ITC is claimed, depreciable basis is reduced by **50% of the ITC amount**:

```text
Depreciable Basis = Eligible Cost Basis − (ITC Amount × 50%)
```

**Worked example — $20M solar CapEx:**

- Eligible basis = $20,000,000
- ITC @ 30% = $6,000,000
- Basis reduction = $6,000,000 × 50% = $3,000,000
- **Depreciable basis = $17,000,000**

### 4.4 With 100% bonus (current default)

```text
Year-1 Depreciation Deduction = Full Depreciable Basis
```

Continuing example: Year-1 depreciation = **$17,000,000** (taken immediately).

---

## 5. Section 179 (2026)

### 5.1 Limits (Rev. Proc. 2025-32, post-OBBBA)

| Item | Amount |
|---|---|
| Maximum §179 deduction | **$2,560,000** |
| Phase-out threshold | **$4,090,000** |
| Fully phased out | **$6,650,000** |

### 5.2 Phase-out mechanics

For every dollar of qualifying property above $4,090,000, the maximum deduction reduces dollar-for-dollar.

**Example:** $5M qualifying property → excess = $910k → max §179 = $2,560,000 − $910,000 = **$1,650,000**.

### 5.3 Order of application

§179 → 100% bonus depreciation → regular MACRS.

### 5.4 Application to the 20 MW deal

Relative to a $180-220M project, the $2.56M §179 cap is small. Bonus depreciation is the dominant Year-1 tool. §179 is useful for smaller equipment packages before bonus applies.

---

## 6. ESG / Carbon / SREC Metrics

### 6.1 Regional reality

| State | SREC market |
|---|---|
| Georgia | No RPS → **no compliance SREC market**. Voluntary / bilateral only. |
| PJM states (VA · PA · MD · NJ · OH · IL · DC · DE) | Compliance market · deep liquidity · premium pricing |
| ERCOT (TX) | Different construct — REC pricing |

### 6.2 Core metrics tracked in `ReserveProofAnchor`

| Metric | Formula | Target |
|---|---|---|
| PUE | Total Facility Energy ÷ IT Equipment Energy | ≤ 1.15 (immersion 1.03-1.10) |
| Carbon intensity | kg CO₂e per MWh of IT load | Site-specific |
| REC / SREC volume | 1 REC = 1 MWh qualifying generation | Variable |
| Additionality | Net-new generation due to project | Required for premium voluntary tiers |
| Vintage matching | Generation year matches consumption year | Mandatory for corporate ESG (24/7 matching) |

### 6.3 Voluntary REC pricing benchmarks (2026)

| Product | Price range ($/MWh) |
|---|---|
| Generic national unbundled RECs | $0.30 – $1.00 |
| Premium regional / hourly-matched | $5 – $40+ |
| Compliance SRECs (PJM Tier I) | Significantly higher, structurally liquid |

### 6.4 Waterfall integration

SREC / REC / carbon revenues sit **below senior debt service and platform fees** but above sponsor promote. Options: (a) flow into equity residual pool for pro-rata, or (b) issue as a separate tokenized tranche (RECToken / CarbonToken).

---

## 7. Combined Capital-Stack Metrics

| Metric | Formula | Target |
|---|---|---|
| Senior LTV / advance rate | Senior Debt ÷ Total Project Cost | 60-70% · up to 75% with strong PPA |
| DSCR | NOI ÷ Annual Debt Service | ≥ 1.25× – 1.40× |
| DSCR (PPA-anchored) | **(Hosting Revenue − Utility Charges − Taxes − Opex) ÷ Debt Service** | Same ≥ 1.25× **but net of PPA demand charges** |
| QROF equity share | QROF Equity ÷ Total Project Cost | 15-25% |
| Effective equity cost | Post-step-up basis adjustment | Compressed by ~7% via QROF alone |
| Total federal tax benefit per $ of QROF equity | (30% step-up × 23.8%) + state | ~7.1% federal on deferred-gain portion |

_ITC tax-equity share row removed — solar / wind ITC cutoff missed. Storage-only ITC available but not modelled in base case._

---

## 8. 20 MW Base Case Quick Reference (~$200M total project)

| Incentive / benefit layer | Illustrative financial value |
|---|---|
| QROF 30% step-up (on $36M equity block) | $10,800,000 basis increase → **~$2,570,000 federal tax savings** vs no QROF |
| 100% bonus depreciation (all equipment, no ITC basis reduction) | Year-1 deduction ~$20-25M · 99% to sponsor pre-flip (no tax-equity partner now) |
| Energy storage ITC (if standalone storage added) | Full 30% baseline with runway through 2033 — optional layer |
| Voluntary RECs / carbon (GA) | Modest residual · GA no compliance market · pair PJM sites for real SREC pricing |
| Section 179 (2026 limit $2.56M) | Small vs stack · strategic use for early-stage equipment |
| **Combined tax & incentive uplift** | **$8-15M** on the 20 MW deal (down from $15-30M with ITC) |

### Base-case source of funds line

```text
Senior $130M + Equipment $24M + QROF $36M + Sponsor/Barak $10M
= $200M sources vs $200M base uses
= 0% contingency headroom (add 5-10% contingency inside project cost line)
```

The $8-15M of remaining tax + incentive uplift (QROF step-up + 100% bonus on full basis + §179) is what lets the QROF equity accept a lower cash pref than conventional accredited equity would demand.

---

## Companion HTML playbook

Print-ready visual version: `fth-trading-system/docs/verticals/tax-esg-incentive-formulas-reference.html`

## Companion calculators

Build queue: [`../09-calculators/inventory.md`](../09-calculators/inventory.md)

## Not tax, legal, or investment advice

All formulas reflect current OBBBA / post-July-4-2025 law and applicable Revenue Procedures. Actual capital-stack sizing, tax-equity partnership documents, and QROF filings require licensed OZ counsel, tax counsel, and CPA administration.
