# PPA Go/No-Go Diligence Pack — 12 Items

Every item below must be extracted from the executed PPA document, its schedules, and the interconnection agreement. **Missing any one of these blocks the senior debt term sheet AND the 506(c) PPM.** Extract in order; each earlier item informs the later ones.

## Items 1-12

### 1 · Delivery point & interconnection

Substation name · node code · physical address · voltage level (typically 46 kV / 115 kV / 230 kV for large-load). Whether interconnection is **energized today** or requires build-out. Any GA PSC review status if the load was previously subject to large-load contract review.

### 2 · Term & expiration

Contract start date · term length (5 / 10 / 15 / 20 yr common) · renewal options · expiration date. Term should meet or exceed the senior-debt amortization schedule + a buffer.

### 3 · Rate structure

Fixed / indexed / hybrid pricing. Escalators (CPI-linked · fixed % · tiered). Peak / off-peak differentials. Any discounts or minimum-quantity provisions. Extract the average all-in $/MWh over the amortization period.

### 4 · Contract capacity & profile

Firm 20 MW vs curtailable. Any load-following, demand-response, or interruptible components. Maximum instantaneous demand. Baseload assumptions embedded in the pricing.

### 5 · Take-or-pay / minimum billing

Minimum monthly / annual demand charges regardless of usage. Curtailment credits or make-whole clauses. This directly drives our downside-case DSCR modeling.

### 6 · Assignability language ⚠️ Go/No-Go

Whether the PPA is (a) freely assignable, (b) assignable with utility consent (not unreasonably withheld), or (c) assignment-restricted. Any change-of-control triggers. Any collateral-assignment permission for the senior lender.

### 7 · Counterparty capacity ⚠️ Go/No-Go

What entity currently holds the PPA (individual · LLC · LP). Does that entity have the corporate authority to assign. Any UCC filings / liens against the PPA. Any prior assignments or attempted assignments.

### 8 · Site-siting constraints in the PPA

Whether the PPA restricts the physical use of the power (some contain "no-crypto-mining" clauses; some are load-neutral). Whether the counterparty specified a use case in the original underwriting.

### 9 · Environmental attributes

Who owns RECs / SRECs / carbon attributes associated with the delivered energy. If the PPA is with a renewable-heavy generator, this matters for green-compute claims and the SREC token line.

### 10 · Termination triggers

Force majeure. Regulatory-change carve-outs. Material adverse change clauses. Default remedies. Rights of the utility to terminate for non-payment or breach.

### 11 · PSC review posture

Whether the load is subject to Georgia PSC 30-day advance contract review (typically only large-load / hyperscale). Whether prior review has been completed.

### 12 · Novation vs assignment ⚠️ Go/No-Go

Whether the utility will accept full novation (original counterparty released, new SPE substituted) or only permit assignment (original retains contingent liability). This affects the true-sale opinion senior lenders will demand.

## The Go/No-Go rule

**Do not sign an equity term sheet before items 1, 2, 6, 7, and 12 are confirmed.**

These five are the go/no-go items — delivery point + term + assignability + counterparty capacity + novation posture. Everything else is pricing detail. If any of the go/no-go items comes back unfavorable, the deal restructures around a different anchor asset — but we do not raise against a PPA whose assignability is contingent or whose counterparty cannot cleanly transfer.

## What happens after items land

Once the four critical items (1, 2, 6, 12) are confirmed:

1. **Capital-stack base column locks** — Sensitivity 2 in [../03-capital-stack/sensitivity.md](../03-capital-stack/sensitivity.md) resolves to point estimates
2. **Senior-lender teasers issue** — six named lenders in [../06-epc-and-ppa/senior-lenders.md](../06-epc-and-ppa/senior-lenders.md)
3. **ReserveProofAnchor schema configures** — see [../06-epc-and-ppa/attestation-schema.md](../06-epc-and-ppa/attestation-schema.md)
4. **12-week sprint activates** — deploy Jan 1, 2027 into the certified QROF tract

## Related

- [Barak 20 MW worked example](./barak-worked-example.md)
- [Rural definition](../04-georgia-playbook/rural-definition.md)
- [EPC contract review](../06-epc-and-ppa/epc-review.md)
