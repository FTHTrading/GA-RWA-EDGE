# Georgia QROF Rural Definition — Site-Selection Discipline

**The statutory rural test is stricter than casual intuition. Verify every tract before signing any option.**

## Statutory language

Per IRC §1400Z-2 as amended by OBBBA (signed July 4, 2025), a **rural area** = any area other than:

1. A city or town with population **greater than 50,000**, **and**
2. Any Census-defined **urbanized area contiguous and adjacent** to such a city or town.

**Both prongs must clear.** Per-tract test, not per-county.

## Practical meaning for the Atlanta metro

The **Atlanta urbanized area extends into multiple counties**. Many tracts that feel rural — low density, outside city limits, agricultural surroundings — still fail the test if they sit inside the urbanized-area boundary contiguous to Atlanta.

### Realistic tract map for Path B

**Likely rural-qualifying (outer tracts):**

- **Jackson** — Commerce / Jefferson outer tracts, I-85 corridor
- **Barrow** — outer tracts
- **Newton** — outer tracts east of Covington
- **Carroll** — outer tracts west of Carrollton
- **Coweta** — far southern tracts, well away from Newnan urbanized fringe

**Unlikely to qualify** (Atlanta urbanized-area contiguity):

- **Clayton** — entirely inside urbanized area
- Most of **Douglas**
- Most of **Coweta**'s Newnan corridor

**Definitively rural** (further out, but wheeling / interconnect distance rises):

- **White** (Helen corridor — direct Helen Corp synergy)
- **Rabun · Union · Fannin · Habersham · Hart · Franklin · Elbert**
- **Bulloch · Emanuel · Jefferson** (South GA — Savannah PoP proximity, lowest land basis)

## Border-state expansion

If the PPA delivery point permits, expanding beyond Georgia opens compliance-market SREC pricing:

| Region | Notes |
|---|---|
| Tennessee River Valley (E TN / N AL / N MS) | TVA territory · cheapest US industrial rates · rural QROF-eligible in many tracts |
| Southwest Virginia | **PJM compliance-market SREC pricing** · deep rural QROF stack |
| Rural upstate South Carolina (Cherokee / Union / Chester) | Duke Energy Carolinas · Charlotte AI-cloud demand overflow |

## Site-selection discipline

For every candidate tract, **before** any option is signed:

1. Confirm tract sits outside urbanized-area boundary per Census 2020 (or 2030 when released) definitions
2. Confirm no municipality > 50k population within the tract or contiguous-adjacent
3. Pull the tract's OZ 2.0 eligibility from the certified 2027 map (available Q4 2026)
4. Request written zoning-verification letter from county zoning official
5. Verify data-center use is permitted (or fits accessory-use classification per local ordinance)
6. File the letter in the QOF diligence packet

**Non-negotiable:** no capital moves before items 1-4 are documented.

## OZ 2.0 nomination window

| Event | Date |
|---|---|
| State nomination window opens | July 1, 2026 |
| State nomination window closes | Sept 29, 2026 |
| Extension available to | Oct 29, 2026 |
| Treasury certification expected | Q4 2026 |
| New zones effective | **Jan 1, 2027** |
| Designation length | 10 years |

## Consequence for the QROF wrapper

If a tract clears the rural test AND appears on the certified 2027 map:

- **30% basis step-up** at year 5 (vs 10% standard QOF)
- **50% substantial-improvement threshold** (vs 100%)
- Federal tax benefit of ~$2.86M on a $40M equity raise (vs no QROF)
- ~$1.9M incremental advantage over standard QOF on the same raise

## Config file

Per-tract candidates: [`../../config/georgia/rural-tracts.json`](../../config/georgia/rural-tracts.json)

Zoning matrix: [`../../config/georgia/zoning-matrix.json`](../../config/georgia/zoning-matrix.json)

## Related

- [PPA diligence pack](../05-deal-templates/ppa-diligence.md)
- [Capital stack sensitivity](../03-capital-stack/sensitivity.md)
- [Tax formulas reference](../02-tax-esg-incentives/formulas.md)
