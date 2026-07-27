# Capital Stack Sensitivity — 20 MW Base Case

Base-case working numbers pending PPA diligence lock. Modular pod all-in CapEx (land + shell + interconnect + pods + immersion + gensets + solar-plus-storage) typically ranges $8-14M per MW at institutional build spec.

## Base-case stack ($200M / 20 MW · $10M per MW)

| Layer | % | Amount | Source / notes |
|---|---|---|---|
| Senior debt | 65% | $130M | Data-center CRE / USDA B&I (rural) / C-PACE. PPA drives higher LTV + lower spread. |
| Equipment / GPU debt | 12% | $24M | Vendor programs · GPU-backed lending (CoreWeave IG-rated pattern) |
| ITC tax equity | 8% | $16M | Solar co-located, placed in service by 12/31/27. 99/1 → 5/95 flip |
| QROF preferred equity | 20% | $40M | Cap-gains sellers · rural 30% step-up · 10-yr hold · Reg D 506(c) via FTH Trading |
| Sponsor + Barak | 5% | $10M | Helen Corp equity + Barak's PPA contribution (blended cash / promote / equity) |
| **Total** | 100% | **$200M** | |

## Sensitivity 1 · Total project cost per MW

| All-in $/MW | Total project | Senior 65% | Equipment 12% | ITC 8% | QROF 20% | Sponsor+Barak 5% |
|---|---|---|---|---|---|---|
| $8M/MW | $160M | $104M | $19M | $13M | $32M | $8M |
| **$10M/MW (base)** | **$200M** | **$130M** | **$24M** | **$16M** | **$40M** | **$10M** |
| $12M/MW | $240M | $156M | $29M | $19M | $48M | $12M |
| $14M/MW | $280M | $182M | $34M | $22M | $56M | $14M |

Equity scales linearly — every $2M/MW cost overrun adds ~$8-10M of equity to raise.

## Sensitivity 2 · Senior advance rate (PPA quality driven)

| Senior LTV | Senior debt | Residual equity | PPA value vs unlocked | Driver |
|---|---|---|---|---|
| 55% | $110M | $66M | Minimal | Weak PPA / assignment contingent |
| 60% | $120M | $56M | ~$8-10M benefit | Standard |
| **65% (base)** | **$130M** | **$46M** | ~$15-18M benefit | Firm PPA · clean assignment |
| 70% | $140M | $36M | ~$20-25M benefit | Strong firm PPA + novation |
| 75% | $150M | $26M | ~$25-30M benefit | Long-term firm + demand response |

**Highest-leverage diligence item — moving from 60% to 70% senior reduces QROF + sponsor equity by ~$20M.**

## Sensitivity 3 · Solar co-location + ITC deadline

| Solar scale | ITC capital | Net equity impact | Deadline risk |
|---|---|---|---|
| None | $0 | +$16M equity required | N/A |
| 5 MW solar | ~$8-10M | Base-case reduction | Low |
| **8-10 MW solar (base)** | **$14-18M** | Base | Manageable with modular schedule |
| 15+ MW solar | $25-30M+ | Larger reduction | Harder to hit 12/31/27 deadline |

Missing the 12/31/27 placed-in-service date eliminates the ITC layer — forcing ~$15-20M more equity.

## Sensitivity 4 · QROF path

| Path | Basis step-up | Equity size | PV of tax benefit | Recommended |
|---|---|---|---|---|
| Pure Atlanta ring (no rural) | 10% | $40-50M | ~$4-5M | Avoid if rural available |
| **Path B · Rural QROF (base)** | 30% | $40-50M | ~$12-15M | **Preferred** |
| Split (ring + rural) | Mixed | Higher complexity | Partial | Only if rural fails |

Path B remains highest-value even after modest wheeling / transmission costs.

## Sensitivity 5 · Combined stress scenarios

| Scenario | Total cost | Senior LTV | ITC | QROF | Equity required |
|---|---|---|---|---|---|
| **Base** | $200M | 65% | Full | Rural 30% | ~$50M |
| Optimistic | $180M | 70% | Full | Rural 30% | ~$32-35M |
| Pessimistic (overrun + weak PPA) | $240M | 55% | Partial | Ring 10% | ~$85-95M |
| No ITC (missed deadline) | $200M | 65% | $0 | Rural 30% | ~$66M |
| Best case | $190M | 72% | Full | Rural 30% | ~$28-32M |

## What moves the needle most

1. **PPA quality / assignability** → directly sets senior advance rate. Single biggest lever. 60% → 70% LTV saves ~$20M equity.
2. **All-in project cost discipline** → every $1M/MW saved reduces equity by ~$0.4-0.5M.
3. **Hitting the 12/31/27 ITC deadline** → preserves $15-20M of tax-equity capital.
4. **Achieving rural QROF status** → triples basis step-up (~$8-10M investor-level tax benefit).

## Base column locks when

All ranges compress to point estimates once the four PPA diligence items land (see [../05-deal-templates/ppa-diligence.md](../05-deal-templates/ppa-diligence.md)): delivery point + term/rate + assignability + entity authority + novation posture.

## Related

- [Tax formulas reference](../02-tax-esg-incentives/formulas.md)
- [PPA diligence pack](../05-deal-templates/ppa-diligence.md)
- [Barak worked example](../05-deal-templates/barak-worked-example.md)
