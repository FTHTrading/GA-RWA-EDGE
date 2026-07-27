# 🧮 Calculators & TREX Models Inventory

**Complete build queue for internal calculators feeding the FTH / Unykorn / LD Capital stack.** Every calculator listed here feeds directly into existing rails (`ReserveProofAnchor`, `CMBSWaterfall`, `DealRegistry`), capital-stack models, and the MCP agent fleet.

---

## 1. Tax & Incentive Calculators (Highest Priority)

| Calculator | What it computes | Key inputs | Output | Priority |
|---|---|---|---|---|
| **QROF / OZ 2.0 Step-Up Calculator** | 10% vs 30% basis step-up · taxable gain at year 5 · federal tax savings @ 23.8% | Deferred gain amount · hold period · rural flag | Step-up $ · tax savings $ · after-tax IRR impact | **P0** |
| **ITC §48E Calculator** _(historical / storage-only)_ | Credit amount · basis reduction (50% of ITC) · eligible vs ineligible costs | Eligible basis · credit % · adders · placed-in-service date | ITC $ · reduced depreciable basis · tax-equity sizing range | **Historical** — solar / wind cutoff missed 7/4/26; storage-only projects still eligible |
| **MACRS + Bonus Depreciation Calculator** | Year-by-year schedule (5/7/15/39-yr) · 100% bonus option · post-ITC basis | Asset category · cost · placed-in-service date · ITC claimed? | Full depreciation schedule + Year-1 deduction | **P0** |
| **Section 179 Calculator (2026)** | Max deduction after phase-out | Total qualifying property placed in service | Available §179 amount (cap $2.56M / phase-out $4.09M) | **P1** |
| **Combined Tax Benefit Stacker** | QROF + ITC + MACRS + §179 in one view | All of the above | Total Year-1 + multi-year tax benefit $ | **P0** |

---

## 2. Tax Equity (TREX) Models

| Model | Purpose | Key features | Priority |
|---|---|---|---|
| **Partnership Flip Model** | Size tax-equity check · model 99/1 → 5/95 flip | Target after-tax IRR (7.5-9.5%) · yield-based vs date-based flip · ITC + depreciation allocation | **P0** |
| **Tax Equity Sizing Engine** | 1.0×-1.3× ITC rule of thumb + full cash-flow | Credit amount · depreciation schedule · investor IRR hurdle · flip year | **P0** |
| **Direct Pay / Transferability Calculator** | Monetize ITC via §6418 transfer or direct pay | Credit amount · buyer discount · eligible entity status | **P1** |
| **Inverted Lease / Sale-Leaseback Variant** | Alternative structure for certain sponsors | Lease payments · residual value · tax allocation | **P2** |

These are the classic **TREX models** institutional tax-equity desks run. Building them internally lets FTH / LD Capital run scenarios in minutes instead of waiting on external advisors for every deal.

---

## 3. Capital Stack & Underwriting Calculators

| Calculator | What it does | Priority |
|---|---|---|
| **Senior LTV / Advance-Rate Sensitivity** | PPA quality → senior % (55-75%) | **P0** |
| **DSCR Engine (PPA-aware)** | NOI ÷ Debt Service, tested **net** of PPA demand charges | **P0** |
| **Full Source & Uses / Capital Stack Builder** | 20 MW base case + sensitivities (cost/MW, senior rate, ITC size, QROF size) | **P0** |
| **Equity Waterfall & Promote Calculator** | Sponsor + Barak promote / cash / equity blend | **P1** |
| **Centrifuge Warehouse Advance Calculator** | 70-90% of eligible NAV on seasoned notes | **P1** |

---

## 4. Technical / Infrastructure Calculators

Inputs derived from Canovate site evaluation criteria + HPC site-layout requirements.

| Calculator | Purpose | Priority |
|---|---|---|
| **Modular Pod Sizing & Power Density** | 1-5 MW (or 20 MW) pod count · rack density · liquid-immersion vs air | **P0** |
| **PUE & Cooling Load Calculator** | Target ≤ 1.15 (immersion 1.03-1.10) · tons of cooling · CRAC / In-Row / Chiller selection | **P0** |
| **UPS / Generator / Redundancy Sizer** | N+1 / 2N · runtime · fuel | **P1** |
| **Raised-Floor & White-Space Planner** | kW / SF · utilization vs full build | **P1** |
| **Site Evaluation Scorecard** | Standardized intake: power · cooling · connectivity · security · certifications | **P0** |
| **Interconnect & Delivery-Point Feasibility** | Voltage · firm capacity · utility feed diversity | **P0** |

---

## 5. ESG / Carbon / SREC Calculators

| Calculator | Purpose | Priority |
|---|---|---|
| **Carbon Intensity & Avoided Emissions** | kg CO₂e / MWh IT load · flared-gas vs grid vs renewable (Crusoe-style) | **P0** |
| **Voluntary REC / SREC Volume & Revenue** | MWh generated → REC volume → $ (GA voluntary vs PJM compliance) | **P1** |
| **Additionality & Vintage Matcher** | Required for premium corporate claims | **P1** |
| **PUE + Carbon Dual Metric Dashboard** | Live feed into `ReserveProofAnchor` | **P0** |

---

## 6. Deal Setup & Operational Tools

| Tool | Description | Priority |
|---|---|---|
| **PPA Go/No-Go Diligence Pack Generator** | 12-item checklist → auto-scored | **P0** |
| **SPE Formation Checklist + Document Pack** | Auto-generates required docs list | **P0** |
| **ReserveProofAnchor Payload Builder** | Turns PPA · EPC FAT/SAT/IST · revenue · SREC into on-chain attestation JSON | **P0** |
| **Client Intake Portal (Asset Originator)** | Barak-style form → feeds `DealOnboardingAgent` | **P0** |
| **Capital Stack Scenario Runner** | Interactive web or spreadsheet that updates all tax + LTV + DSCR live | **P0** |
| **Georgia Rural QROF Screener** | Tract + urbanized-area + >50k city test | **P0** |
| **Modular EPC Milestone & LD Tracker** | Links to 12-clause checklist | **P1** |

---

## 📅 Recommended Internal Build Sequence (Next 30-60 Days)

**Phase 1 — Core Tax & Stack (Weeks 1-2)**

1. QROF Step-Up Calculator
2. MACRS + 100% Bonus Depreciation Calculator (no ITC basis reduction — solar / wind cutoff missed)
3. Partnership Flip / TREX Sizing Model
4. Full Capital Stack + DSCR Sensitivity

**Phase 2 — Technical + Site (Weeks 3-4)**

5. Site Evaluation Scorecard (digital version of the uploaded Canovate Excel)
6. Modular Pod + PUE + Cooling Sizer
7. PPA Diligence Auto-Scorer

**Phase 3 — Integration (Weeks 5-6)**

8. ReserveProofAnchor Payload Generator
9. ESG / Carbon Intensity Dashboard
10. Client Intake → `DealRegistry` handoff

---

## 🛠️ Delivery formats

Every calculator ships in three formats to serve different consumers:

- **Excel / Google Sheets** — fastest to iterate, audit-friendly, familiar to CPAs and lenders
- **Streamlit / Next.js internal tool** — for scenario running and client demos
- **Direct inputs into the MCP agent fleet** — `CapitalStackAgent` and `DealOnboardingAgent` consume the same formulas programmatically

---

## 🎯 Bottom line

Highest-ROI internal builds are the **QROF / MACRS + 100% bonus / §179 / TREX (storage-only) suite** and the **PPA-aware capital-stack + DSCR engine**. Solar / wind ITC §48E section is retained as historical reference — the begin-construction cutoff was missed July 4, 2026. Everything else (site scorecard, PUE, carbon, attestation payloads) feeds the same system and makes Georgia edge-DC deals repeatable and lender-ready.

Detailed specifications (inputs · formulas · output schema · unit tests) for each calculator ship as separate markdown files in this directory once the P0 queue enters implementation.

## Reference material

Formula reference: [`../02-tax-esg-incentives/formulas.md`](../02-tax-esg-incentives/formulas.md)

HTML companion: `fth-trading-system/docs/verticals/tax-esg-incentive-formulas-reference.html`
