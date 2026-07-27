# Capital Stack Sensitivity — 20 MW Base Case

Base-case working numbers pending PPA diligence lock. Modular pod all-in CapEx (land + shell + interconnect + pods + immersion + gensets) typically ranges $8-14M per MW at institutional build spec.

> ⚠️ **Solar / Wind ITC §48E — cutoff missed.** Begin-construction safe harbor lapsed July 4, 2026. Solar ITC removed from all layers below. Storage-only ITC survives through 2033 but is not modelled here.

## Base-case stack ($200M / 20 MW · $10M per MW)

| Layer | % | Amount | Source / notes |
|---|---|---|---|
| Senior debt | 65% | $130M | Data-center CRE / USDA B&I (rural) / C-PACE. PPA drives higher LTV + lower spread. |
| Equipment / GPU debt | 12% | $24M | Vendor programs · GPU-backed lending (CoreWeave IG-rated pattern) |
| QROF preferred equity | 18% | $36M | Cap-gains sellers · rural 30% step-up · 10-yr hold · Reg D 506(c) via FTH Trading |
| Sponsor + Barak | 5% | $10M | Sponsor equity + Barak's PPA contribution (blended cash / promote / equity) |
| **Total** | 100% | **$200M** | |

_ITC layer (formerly 8% / $16M) removed — cutoff missed. Equity gap absorbed by widening QROF share from 20% to 18% and letting slightly higher senior LTV close the remainder (see Sensitivity 2)._

## Sensitivity 1 · Total project cost per MW

| All-in $/MW | Total project | Senior 65% | Equipment 12% | QROF 18% | Sponsor+Barak 5% |
|---|---|---|---|---|---|
| $8M/MW | $160M | $104M | $19M | $29M | $8M |
| **$10M/MW (base)** | **$200M** | **$130M** | **$24M** | **$36M** | **$10M** |
| $12M/MW | $240M | $156M | $29M | $43M | $12M |
| $14M/MW | $280M | $182M | $34M | $50M | $14M |

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

## Sensitivity 3 · QROF path (Rural vs Ring)

_This section replaces the prior "Solar co-location + ITC deadline" sensitivity, which no longer applies (solar ITC cutoff missed July 4, 2026)._

| Path | Basis step-up | Equity size | PV of tax benefit | Recommended |
|---|---|---|---|---|
| Pure Atlanta ring (no rural) | 10% | $36-46M | ~$4-5M | Avoid if rural available |
| **Path B · Rural QROF (base)** | 30% | $36-46M | ~$12-15M | **Preferred** |
| Split (ring + rural) | Mixed | Higher complexity | Partial | Only if rural fails |

Path B remains highest-value even after modest wheeling / transmission costs.

## Sensitivity 4 · MACRS + 100% bonus depreciation (still available)

MACRS + 100% bonus continues to apply to non-solar equipment (pods, IT load, cooling, land improvements). This is the primary remaining depreciation benefit.

| Asset class | Recovery period | Bonus eligible? | Year-1 benefit on $1M CapEx |
|---|---|---|---|
| IT equipment (pods, GPUs, immersion) | 5-yr | Yes | 100% Year-1 deduction ($1.0M × 21% tax = ~$210k shield) |
| UPS · switchgear · batteries | 5- or 7-yr | Yes | Same magnitude |
| Land improvements | 15-yr | Yes | Same magnitude on Year-1 |
| Building / structural | 39-yr | No | Straight-line only |

_No ITC basis reduction applies (no ITC being claimed) — full CapEx is depreciable._

## Sensitivity 5 · Combined stress scenarios

| Scenario | Total cost | Senior LTV | QROF | Equity required |
|---|---|---|---|---|
| **Base** | $200M | 65% | Rural 30% | ~$46M |
| Optimistic | $180M | 70% | Rural 30% | ~$30-33M |
| Pessimistic (overrun + weak PPA) | $240M | 55% | Ring 10% | ~$80-90M |
| Best case | $190M | 72% | Rural 30% | ~$25-30M |

## What moves the needle most

1. **PPA quality / assignability** → directly sets senior advance rate. Single biggest lever. 60% → 70% LTV saves ~$20M equity.
2. **All-in project cost discipline** → every $1M/MW saved reduces equity by ~$0.4-0.5M.
3. **Achieving rural QROF status** → triples basis step-up (~$8-10M investor-level tax benefit).
4. **MACRS + 100% bonus on non-solar equipment** → preserved. Provides ~15-20% of remaining tax shield without ITC.

## Base column locks when

All ranges compress to point estimates once the four PPA diligence items land (see [../05-deal-templates/ppa-diligence.md](../05-deal-templates/ppa-diligence.md)): delivery point + term/rate + assignability + entity authority + novation posture.

## Related

- [Tax formulas reference](../02-tax-esg-incentives/formulas.md)
- [PPA diligence pack](../05-deal-templates/ppa-diligence.md)
- [Barak worked example](../05-deal-templates/barak-worked-example.md)
