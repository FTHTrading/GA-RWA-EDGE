# Modular EPC Contract Review — 12 Clauses + Red Flags

**Counsel-ready checklist for 1-20 MW modular / liquid-immersion pod deployments inside an FTH Trading Asset SPE.**

## Preferred contracting form

| Form | Fit for modular | Recommendation |
|---|---|---|
| **Full EPC** (Engineering, Procurement, Construction) | Single throat to choke. Preferred by senior lenders. | Strongly preferred |
| Design-Build | Owner retains tighter design oversight. More interface risk. | Acceptable with caveats |
| Design-Bid-Build | Destroys the schedule advantage. | Avoid |

## The 12 critical clauses

### A · Scope & Interfaces — Highest risk

Must explicitly cover: detailed design · factory fabrication · Factory Acceptance Testing (FAT) · transport · site civil / pad · installation · integration with utility interconnect / PPA delivery point · commissioning · Integrated Systems Testing (IST). Liquid-immersion specific: coolant type · containment · leak detection · heat-rejection interface. Modules designed to the voltage / fault current / protection scheme of the PPA delivery point.

**Demand:** explicit interface schedule listing every hand-off point between contractor scope and SPE / utility scope, with responsibility matrix.

### B · Price Structure — High risk

**Fixed-price (lump sum) strongly preferred by senior lenders.** Any cost-plus / unit-price elements narrowly defined and capped. Allowances / contingencies itemized and controlled by the SPE, not the contractor.

**Demand:** single lump-sum price · contractor contingency 3-5% locked · SPE contingency 5-10% held separately.

### C · Schedule & Liquidated Damages — High risk

Guaranteed substantial completion / COD with **daily LDs**. High enough to cover debt service + lost hosting revenue; capped at 10-15% of contract price. "Time is of the essence" + early-warning obligations. Schedule relief only for true force majeure or SPE-caused delays.

**Demand:** daily LD $ = PPA demand charges + expected daily hosting revenue lost + senior debt service · cap at 15%.

### D · Performance Guarantees — Non-negotiable for lenders

Quantitative and tested:

- IT load capacity (MW) under continuous full load
- **PUE ≤ 1.15** (liquid immersion often 1.03-1.10)
- Cooling capacity and supply temperatures at design ambient
- Redundancy (N+1 or 2N) with successful failover testing
- Uptime / availability tied to recognized standard (Tier III equivalent for edge)

**Remedies:** make-good obligation first, then Performance Liquidated Damages (PLDs) capped at 10-15% of contract price. Failure to meet minimum performance prevents final acceptance and final payment.

### E · Acceptance & Commissioning — High risk

Three staged gates with objective pass/fail criteria:

- Factory Acceptance Test (FAT) with SPE or IE present
- Site Acceptance Test (SAT)
- Integrated Systems Test (IST) under load

**Critical for our stack:** FAT / SAT / IST certificates become prime inputs to `ReserveProofAnchor`. Hash each certificate on chain at completion → feeds senior lender + QROF investor reporting automatically.

### F · Warranties & Defects Liability — Medium risk

- Minimum 2-year comprehensive warranty on entire module
- Longer warranties on major equipment (transformers · chillers · immersion systems) from OEMs
- Clear defects-liability period after COD
- Obligation to **repair or replace** — not monetary-only remedies

### G · Payment Milestones & Retainage — Medium risk

Milestone-based: engineering complete → FAT → delivery → installation → SAT/IST → final acceptance.

**Demand:** 15% retainage · at least 5% held until 12 months post-COD to cover warranty claims.

### H · Title, Risk of Loss & Insurance — Medium risk

Title and risk transfer only upon **final acceptance** (or carefully staged). Contractor maintains cargo / erection-all-risk / liability insurance naming SPE and senior lenders as additional insureds / loss payees. Waiver of subrogation.

### I · Change Orders — Medium risk

Strict process. Contractor cannot self-approve material changes. Pricing transparent (unit rates or agreed methodology). No automatic schedule extension without demonstrated critical-path impact.

### J · Termination & Step-In — High risk

Termination for convenience (with demobilization costs) and for cause. **Senior-lender step-in rights and assignment provisions** so lender can take over the contract if SPE defaults. Survival of warranties and IP licenses after termination.

**Critical:** lenders will not close without a clear consent-to-assignment + step-in agreement from the EPC contractor. Get this signed in the EPC itself, not a side letter.

### K · Force Majeure & Supply Chain — Medium risk

**Narrow definition.** Ordinary supply-chain delays are NOT force majeure. Explicit treatment of long-lead equipment and tariff impacts. Contractor obligated to maintain buffer inventory or alternative sourcing for critical components.

### L · Expansion / Options — Strategic

Pre-agreed pricing and lead times for additional identical modules (important for phased 20 MW builds). Right of first refusal on future capacity at the same site.

## Red flags — walk away or heavily re-trade

- ⛔ Vague performance language ("approximately Tier III", "industry-standard PUE")
- ⛔ Uncapped or missing liquidated damages
- ⛔ Title / risk transfer on delivery rather than after IST
- ⛔ Broad force-majeure including ordinary supply-chain delays
- ⛔ Contractor-controlled contingencies or open-ended change-order rights
- ⛔ No lender step-in or assignment rights
- ⛔ Warranty that excludes liquid-immersion components or software / controls
- ⛔ Long-lead equipment from FEOC (foreign entity of concern) jurisdictions — blocks USDA B&I eligibility and complicates ITC transferability under OBBBA FEOC restrictions

## ReserveProofAnchor evidence chain

```text
EPC MILESTONE           →  ATTESTATION           →  ON-CHAIN ANCHOR
Engineering complete    →  IE sign-off           →  hash design drawings, load calcs
FAT (factory)           →  IE + SPE witness      →  hash FAT cert, videos, telemetry
Transport / delivery    →  bill of lading        →  hash BOL, insurance certs
Installation            →  utility interconnect  →  hash interconnect agmt
SAT (site)              →  IE sign-off           →  hash SAT cert
IST (integrated)        →  IE + lender + SPE     →  hash IST cert + test data
Final acceptance        →  release title         →  hash acceptance + as-builts
Warranty period start   →  begin defects clock   →  scheduled anchor updates
```

## Four non-negotiables

1. **Fixed price**
2. **Quantitative performance guarantees with PLD backstop**
3. **10-15% retainage held past IST + warranty period**
4. **Full assignability + step-in to SPE and senior lenders**

Score every incoming EPC term sheet against clauses A-L before counsel gets involved. Term sheets that fail three or more clauses get returned; passing ones move to counsel for detailed negotiation.

## Companion HTML

Full visual version: `fth-trading-system/docs/verticals/modular-epc-contract-review.html`
