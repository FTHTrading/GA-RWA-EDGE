# FLEET AUDIT CHECKLIST
## On-site verification of miners, hashrate, and ownership · Barak/Brock Site

> **Purpose:** Confirm that the 1,200-unit fleet cited in the acquisition documents is (a) physically on the Premise, (b) operational at rated hashrate, and (c) transferable at closing. Resolves the nameplate reconciliation flag from Master Loop v1.1 §1.1.
>
> **Who runs it:** LD Capital-designated fleet auditor (recommended: an independent third-party mining-ops firm, not the seller's technician). Two auditors present, single record hash-anchored to `ReserveProofAnchor`.
>
> **Delivery:** signed PDF + hash-anchored on-chain record, referenced back into the Phase 0 gate as `miners_on_site` = one of { YES-ALL | YES-PARTIAL (count) | NO }.

---

## Nameplate reconciliation warning

Per Master Loop v1.1 §1.1 note: 1,200 units at 10 MW implies ~8.3 kW/unit, which is high for S19-class miners (~3 kW). Three possible resolutions:

1. Count is higher than 1,200 (some units are multi-hasher or high-density).
2. Some units are next-gen (S21, S21 Pro Hyd) drawing 3.5–6 kW each.
3. The 10 MW is contracted headroom, not fully populated — actual draw is 3.6–4.5 MW.

The audit resolves this by counting units, reading nameplate power/hashrate, and taking a live power draw measurement at the switchgear.

---

## Pre-audit prep

### Documents to obtain from seller before arrival
- [ ] Fleet inventory list (unit model, serial, ownership document / bill-of-sale reference).
- [ ] Insurance certificate covering the units at the Premise.
- [ ] Mining pool account statement for the last 30 days (pool payouts, worker hash contributions).
- [ ] Utility bill for the last 6 months showing power drawn.
- [ ] Container floor plan showing miner racking layout.
- [ ] Any UCC-1 filings that might indicate a third-party lien on the fleet.

### Equipment auditor should bring
- [ ] Calibrated clamp meter (for switchgear draw verification).
- [ ] Thermal camera (for hot-spot inspection, dead-unit identification).
- [ ] Wi-Fi laptop with mining-pool dashboard access.
- [ ] Barcode / QR scanner for unit serials.
- [ ] Sealed evidence bags for pulled sample units (if seller consents to random pull).

---

## Section 1 — Physical presence

For each of the 9 containers on the Premise:

- [ ] Container number: _______  Location on site: _______
- [ ] Number of miner units racked and connected: _______
- [ ] Number of empty rack slots: _______
- [ ] Photograph each container's interior + a scan of at least 20 unit serial numbers per container.
- [ ] Cross-check scanned serials against the seller's inventory list. Discrepancies logged.

**Aggregate:**
- [ ] Total units physically counted across all containers: _______
- [ ] Total units on seller's inventory list: _______
- [ ] Discrepancy (list vs. counted): _______  Reason: _______

### Off-site or missing units
- [ ] Are any units listed on the inventory but not on-site? If yes, where? Under what documentation?
- [ ] Are any units on-site but not on the inventory? If yes, whose are they?

---

## Section 2 — Operational state

### Container-level power draw
- [ ] Read total site power draw at main switchgear during the audit window: _______ kW.
- [ ] Read power draw per container: C1 ___, C2 ___, C3 ___, C4 ___, C5 ___, C6 ___, C7 ___, C8 ___, C9 ___.
- [ ] Cross-check against utility interval-meter data for the same window (variance ≤ 5%).

### Miner-level operation
- [ ] Randomly select 30 units across containers.
- [ ] Confirm each is (a) powered on, (b) has active network, (c) is currently hashing at ≥ 90% of nameplate.
- [ ] Log unit model, nameplate hashrate, observed hashrate, temperature.

### Pool-side confirmation
- [ ] Verify that the Wi-Fi / IP-visible workers match the physical units.
- [ ] Pull the last 24-hour pool payout report and compare hash contribution to nameplate at ≥ 60% (typical loss factor).

### Dead / degraded units
- [ ] Count of units powered but not hashing: _______
- [ ] Count of units offline entirely: _______
- [ ] Estimated cost to bring them online (repair, replacement fan/PSU/hashboard, replace entirely): _______

---

## Section 3 — Ownership and transferability

For each ownership question, obtain a signed statement from the seller AND corroborate with the referenced document:

- [ ] Are the units owned outright by the seller (or by the acquisition target entity), or leased?
- [ ] If leased, from whom, and can the lease be assumed or paid off at closing?
- [ ] Are any units subject to a UCC-1 filing? Search of state UCC records confirms/denies.
- [ ] Are any units subject to a mining-pool contract that would restrict resale (rare, but happens with "buy-back" agreements)?
- [ ] For the 4 co-owners besides Barak, does each acknowledge inclusion of the units in the sale?
- [ ] Is there any tax lien, judgment, or bankruptcy proceeding that would encumber the fleet?

---

## Section 4 — Nameplate reconciliation (the critical section)

Compute:

```
sum_nameplate_power_kW = sum over all units of (unit_nameplate_power_watts / 1000)
sum_observed_power_kW  = utility_interval_meter reading during audit
observed / nameplate ratio = ______
```

If observed / nameplate is between 0.85 and 1.05 → fleet is running roughly at nameplate. Report to Phase 1 as `mining_at_nameplate == YES`.

If ratio is materially different → reconcile. Common causes:
- Under-clocked units (lower J/TH, lower kW, lower hash).
- Dead units (draw zero, count in fleet inventory but not in hash).
- Nameplate lookup error (auditor pulled wrong spec sheet for the unit model).

The Phase 1 mining-yield model MUST use the *observed* power draw and the *observed* hashrate — not the nameplate — as the base case. Nameplate becomes the aspirational case.

---

## Section 5 — Verdict

Fill one:

- [ ] **YES-ALL** — the fleet as documented is present on-site, operational at reasonable percentage of nameplate, and transferable to the Site SPE at closing.
- [ ] **YES-PARTIAL** — the fleet is on-site but with material shortfall (count / operational %). Attach reconciliation and re-priced acquisition recommendation.
- [ ] **NO** — the fleet is not on-site as documented. Recommend acquisition price reflect PPA + infrastructure only; miners priced separately or contingent on delivery.

Auditor 1 signature: _____________________________  Date: _______
Auditor 2 signature: _____________________________  Date: _______

---

## Post-audit

1. Two auditors independently sign the report.
2. SHA-256 hash the signed PDF.
3. `ReserveProofAnchor.anchorDocument(dealId, "FLEET-AUDIT-<date>", sha256, uri)`.
4. Deliver signed PDF + on-chain receipt to LD Capital counsel.
5. Feed the Verdict field into Phase 0 gates as `miners_on_site`.
