# Barak Site — Verified Deal Facts

**Working document. Confidential.** Superseded PPA sensitivity assumptions in prior artifacts.

## Confirmed as of July 27, 2026

| Item | Value | Notes |
|------|-------|-------|
| **Current load** | **5 MW** | Existing, operating |
| **Existing use** | **721 bitcoin miners** | Currently operational at the site |
| **PPA rate** | **4.9 ¢/kWh** | Fixed rate, delivered |
| **Utility posture** | **Deregulated gas zone** | Enables gas-hybrid / gas-only expansion optionality |
| **Site status** | Operating today | Interconnect energized; utility letter effectively pre-issued via active load |

## PPA cost math (locked)

```text
Annual electricity cost @ 5 MW baseload:
  5,000 kW × 8,760 hr × $0.049 = $2,146,200 / year
  Round to $2.15M/yr

Monthly electricity cost: ~$179k
Per-MW per-year: ~$429k
```

**This becomes CMBSWaterfall Priority 1** for the SPE — utility payment sweeps before senior debt service. See `docs/06-epc-and-ppa/epc-review.md` and `contracts/src/paths/cmbs/CMBSWaterfall.sol`.

## What this changes vs. prior 20 MW modeling

The prior sensitivity tables in `docs/03-capital-stack/sensitivity.md` used a **20 MW greenfield** anchor at ~$200M project cost. **The Barak site is different**:

- **Existing operational site**, not greenfield
- **5 MW today** (not 20 MW) — expansion may be part of the plan but the anchor is the existing power position
- **721 miners already running** — represents baseline revenue AND an operational business the SPE either buys out, coexists with, or converts to AI hosting
- **Deregulated gas zone** — expansion path via gas gensets / gas-hybrid without regulated-utility interconnect queue

## Revised base-case sizing (5 MW conversion + expansion)

Working assumption — refine after Barak diligence + site walk. Note: solar co-location layer removed from base case because the **solar ITC begin-construction safe harbor lapsed July 4, 2026**. Storage-only ITC survives through 2033 but is not modelled here.

| Layer | Approx. Amount | Purpose |
|------|-----------|---------|
| Land acquisition / lease buyout | $1.0-3.0M | Take title or perpetual leasehold |
| Miner-contract buyout (existing 721 miners) | $2.0-4.0M | Terminate or assume; assumes some contracts freely terminable |
| Immersion retrofit (5 MW liquid) | $8.0-10.0M | Convert air-cooled miner racks to immersion for AI-workload readiness |
| Interconnect + electrical upgrades | $2.0-3.0M | If expanding beyond 5 MW |
| Working capital + contingency | $2.0-4.0M | Standard 10-15% headroom |
| **Total project cost estimate** | **$15-24M** | **Base case: ~$20M** |

## Revised capital stack (~$20M base case)

| Layer | % | Amount | Source |
|------|---|--------|--------|
| Senior debt | 60% | $12.0M | CRE / USDA B&I (if rural QROF confirmed) / C-PACE |
| Equipment / GPU debt | 15% | $3.0M | Vendor programs, GPU-backed lending |
| QROF preferred equity | 20% | $4.0M | Cap-gains sellers, rural 30% step-up if tract clears |
| Sponsor + Barak | 5% | $1.0M | Sponsor + Barak (PPA contribution — cash/promote/equity blend) |
| **Total** | 100% | **$20M** | Assumes rural QROF; falls back to standard QOF if not |

_ITC tax-equity layer (formerly ~$2M / 8%) removed — solar ITC cutoff missed. Equity gap absorbed by widening QROF share from 32% to 20% of a smaller total cost (project cost drops ~$5M because solar co-location is no longer being built for tax purposes)._

**PPA quality note:** at 4.9¢/kWh fixed, the PPA scores exceptionally well on rate structure (max), delivery point (max), capacity firmness (max), site-use restrictions (max — active mining proves permissive use). Weakest items to verify: assignability language, term length, novation posture. Preliminary PPA scorecard: **20+/24 → senior LTV 65-70%.**

## Path B rural QROF verification (open)

The site is in the Atlanta market. Rural QROF eligibility depends on:

- Tract sits outside any city / town > 50,000 population, AND
- Tract sits outside any Census-defined urbanized area contiguous / adjacent to such city

**Not yet verified.** Once the site's exact parcel is confirmed:

1. Pull tract ID from the 2020 Census map
2. Confirm no municipality > 50k population within the tract
3. Confirm the tract is outside the Atlanta urbanized-area boundary
4. Verify the tract appears on the 2027 QOZ certification (Q4 2026)

**Fallback:** if the tract fails the rural test, standard QOF applies (10% step-up instead of 30%). Sizing math still works — cap-gains investors receive ~$1.9M smaller federal tax benefit, so QROF cash pref rises modestly.

## Contracted-hosting revenue projection

Working assumption (verify with AI-cloud offtake counterparty):

```text
5 MW IT load × $150/kW/month hosting rate × 12 months = $9.0M / year gross revenue

Less:
  Utility (PPA @ 4.9c/kWh × 5 MW × 8760 hr):    $2.15M/yr  ← Priority 1 in CMBSWaterfall
  Opex (staffing, maintenance, insurance):       $0.80M/yr
  Net Operating Income before debt service:      $6.05M/yr

At 60% senior LTV ($15M) at 850 bps over 15 yr:
  Annual debt service ~ $1.85M/yr
  DSCR = $6.05M / $1.85M = 3.27x   (comfortably above 1.25x underwrite gate)
```

**Note:** hosting rate benchmark is Applied Digital-tier ($150/kW/month is at low end for retail AI hosting; $200-250/kW/month for high-density GPU colo). Actual rate depends on offtake counterparty tier (Lambda / CoreWeave / regional AI cloud). Underwrite with a $100/kW/month floor for downside case.

## Deregulated gas zone — what it enables

Georgia has selectively deregulated natural-gas retail markets. Being in a deregulated zone means:

1. **Direct gas supply contracts** — competitive procurement, not tariff-locked
2. **Gas-hybrid expansion possible** — install gensets or reciprocating engines to add capacity beyond the 5 MW PPA envelope without waiting on a regulated-utility interconnect
3. **Emissions attestation required** — every MWh of gas-generated electricity must be recorded via `GasAttestation.sol` in the RWA stack, including source fuel + emissions factor
4. **NOT REC-eligible** — gas-generated MWh cannot mint SRECs/RECs. Solar co-location is the only route to environmental attributes here.

Expansion beyond 5 MW would look like:

- Option A: solar + battery expansion, RPS-neutral (no compliance market in GA anyway)
- Option B: gas gensets — faster, but must attest emissions and cannot claim green-compute premium on gas-sourced MWh
- Option C: hybrid — solar for base + gas for peak or backup

## Open diligence items (for Barak conversation)

**Go/No-Go items (must resolve before senior term sheet):**

1. **PPA term length** — how many years remaining at 4.9¢?
2. **Assignability language** — free / consent-required / restricted?
3. **Barak entity capacity** — org chart, corporate authority, UCC search
4. **Utility novation posture** — full novation (release Barak) vs assignment-only (Barak retains contingent liability)
5. **Existing 721 miner contracts** — assumable, terminable, or must be respected?

**Additional diligence:**

6. Exact parcel ID and tract number (rural QROF verification)
7. Take-or-pay clauses / minimum billing charges beyond 4.9¢ energy rate
8. Environmental attribute ownership (RECs / carbon)
9. Termination triggers and cure periods
10. Any siting restrictions or use covenants
11. Fiber carrier count + latency to Atlanta / Dallas AI-cloud PoPs
12. Water source / makeup water availability (immersion needs modest but nonzero water)

## Deal sprint alignment

- **Now → Q4 2026:** Barak diligence + entity structure + option agreement
- **Q4 2026:** Fund formation (QROF or standard QOF depending on tract), 506(c) PPM
- **Dec 31, 2026:** Do NOT deploy pre-2027 capital (OZ 2.0 rules)
- **Jan 1, 2027:** Deploy — QROF closes, land / PPA-assignment executed, solar-co-location construction begins
- **Q3-Q4 2027:** First contracted hosting revenue; conversion complete

## Companion artifacts

- Full PPA diligence pack: [`ppa-diligence.md`](./ppa-diligence.md)
- Capital-stack sensitivity: [`../03-capital-stack/sensitivity.md`](../03-capital-stack/sensitivity.md)
- Rural QROF screener: [`../04-georgia-playbook/rural-definition.md`](../04-georgia-playbook/rural-definition.md)
- Tax formulas reference: [`../02-tax-esg-incentives/formulas.md`](../02-tax-esg-incentives/formulas.md)
- Calculator suite (Python): [`../../scripts/calculators.py`](../../scripts/calculators.py) — `demo` command runs against these Barak facts

## Not tax, legal, or investment advice

All figures are planning-grade and require Barak's actual PPA document review + licensed OZ / tax / securities counsel before any capital moves.
