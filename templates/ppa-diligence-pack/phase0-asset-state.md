# PHASE 0 — ASSET-STATE FORK & DILIGENCE GATE
## Barak/Brock modular BTC mining unit — Georgia 10 MW PPA

> **This is the fork that everything downstream depends on.** Whether the site is a running operation or a dark shell + PPA changes what you pitch, how you underwrite, what you tokenize in Phase 4, and whether you can honestly claim cash flow. Do not advance to Phase 1 without the four gating inputs at the bottom of this document.

---

## 1. The three-state fork

```
                                Phase 0
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
        RUNNING path         DARK-SHELL path        NO-GO path
        ─────────────         ────────────────       ──────────
   PPA_status = LIVE         PPA_status = DORMANT   PPA_status = TERMINATED
   miners on site AND        miners maybe elsewhere OR non-assignable
   producing hashrate        PPA reactivatable      OR non-pledgeable
                             (with cost)

   Pitch: seasoned            Pitch: PPA-assignment  HALT.
   cash-flow acquisition      asset + reactivation   The scarce asset (the
   at ~4c power.              plan. Re-priced deal.  contracted power) is
                                                     gone or unusable.
   Phase 4 wraps NOI          Phase 4 wraps
   (PPACashflowVault).        contract stream
                              (PPAOfftakeStreamVault).
```

Key rule: **the label RUNNING or DARK-SHELL must appear in every downstream artifact** (mining yield report, power spread, RWA structure, one-pager, portal). No downstream reader can accidentally treat a dark-shell asset as producing live cash flow.

---

## 2. Why this fork matters — impact on the capital story

| Dimension | RUNNING path | DARK-SHELL path |
|---|---|---|
| **Narrative** | "Acquiring a seasoned 6 MW mining operation with 4 MW idle upside and a 7-year 4c PPA." | "Acquiring the PPA assignment and infrastructure; miners to be racked; site reactivation scoped." |
| **Basis presented** | $5M acquisition; all-in basis includes any operational catch-up. | $5M acquisition + fill capex ($1.5-2.3M) + reactivation cost (TBD). Do not print $5M without labeling. |
| **Cash-flow claim** | Trailing X months of realized net cash flow, attested by meter data. | **No cash-flow claim.** Contracted revenue only, discounted. |
| **Phase 4 tokenization** | `PPACashflowVault` — wraps realized NOI. Underwrites like private-credit senior against seasoned digital-infra cash flow. | `PPAOfftakeStreamVault` — wraps contract-stream claim. Underwrites like a receivables purchase with counterparty-credit risk on the utility. Thinner market. |
| **Best Stage-1 lender** | Peachtree bridge / Access Point Financial / community-bank participation against realized DSCR. USDA B&I possible. | USD.AI-style non-recourse GPU-backed vault ONCE miners are racked and metered. Before that: sponsor equity + QROF equity + USDA B&I subordinate against the PPA asset value. |
| **Timeline to Phase 4 tokenization** | 3-6 months (attest, wrap, mint). | 9-12 months (reactivate power, rack miners, run 90 days, attest, wrap). |
| **Downside if wrong label used** | If pitched as DARK-SHELL when actually running, no material downside — pitch is under-selling. | If pitched as RUNNING when actually dark, **securities-fraud exposure** the moment a subscriber wires against a false cash-flow claim. |

---

## 3. Diligence checklist per fork branch

### 3.1 If RUNNING is claimed, verify:
- [ ] Utility invoices for the last 6+ months showing power drawn at the site.
- [ ] Miner-pool payout records (payout wallet, hashrate history, payout USD).
- [ ] On-site inspection or drone video showing miners powered and hashing.
- [ ] Metered hashrate ≥ 60% of nameplate for the last 90 days (allows for downtime).
- [ ] Signed operator attestation of trailing NOI, hash-anchored via `ReserveProofAnchor.anchorDocument`.

### 3.2 If DARK-SHELL is claimed or discovered, verify:
- [ ] PPA still exists (not force-majeured out, not terminated for non-payment).
- [ ] Written statement from utility that PPA can be reactivated under existing pricing.
- [ ] Any arrears / reconnection deposit / dormancy-restart fee quantified.
- [ ] Physical inventory of miners: where they are, condition, ownership documentation.
- [ ] Reactivation cost budget: power turn-on, miner racking, network/fiber restore, security re-arm.

### 3.3 If NO-GO indicators surface:
- [ ] Utility notice of termination on file.
- [ ] Non-assignment clause not waivable by utility counsel.
- [ ] Any pending FERC/PSC action against the premise.

---

## 4. The Phase 4 tokenization impact (why "consent to pledge" is separate from "consent to assign")

The PPA can be assignable to the SPE for purchase (a change of counterparty on the buyer side of the PPA) without being pledgeable to a lender or securitizable to token-holders. These are two separate consents:

- **Assignment consent** — utility allows the PPA to be transferred from current owner to the Site SPE.
- **Pledge / receivable-assignment consent** — utility acknowledges that the PPA receivable (or the SPE's revenue derived from it) may be pledged as collateral to a lender or securitized to a tokenized vault.

Phase 4 fails silently if only the first consent is obtained. The vault would attempt to route on-chain revenue from a receivable it does not have counterparty-approved authority to redirect. Obtain both in Phase 0, in writing.

---

## 5. The four hard gates to pass Phase 0

The operator must return values for these four inputs before Phase 1 begins. All four required — no partial advance.

```
1. ppa_status                              = { LIVE | DORMANT | TERMINATED }
2. miners_on_site                          = { YES-ALL | YES-PARTIAL (count) | NO }
3. consent_to_pledge_or_assign_receivable  = { CONFIRMED-IN-WRITING | REQUESTED-PENDING | NOT-OBTAINED | NOT-REQUIRED-PER-COUNSEL }
4. large_load_carve_out_applies_to_site    = { CONFIRMED-PSC | PENDING | NOT-APPLICABLE }
```

Recommended additional inputs (soft-gate — do not advance to Phase 4 without them):

```
5. ppa_reactivation_cost_usd               = numeric (0 if RUNNING)
6. miners_included_in_price                = { YES | NO | PARTIAL }
7. assignment_consent_required             = { YES-WAIVABLE | YES-NOT-WAIVABLE | NO }
8. co_owner_signoff                        = { ALL-SIGNED | N-OF-4-SIGNED | PENDING }
9. ppa_reactivation_possible               = { YES-CONFIRMED | LIKELY-COUNSEL-VIEW | UNCERTAIN | NO }
```

---

## 6. Deliverables emitted alongside this fork doc

1. `ppa-verification-letter.md` — the letter to send to power provider + seller's counsel to confirm PPA status, assignability, and pledgeability.
2. `fleet-audit-checklist.md` — the on-site checklist for confirming miner presence, hashrate, and ownership.
3. `co-owner-consent-checklist.md` — the four (non-Barak) co-owner sign-off pack.

---

*Not tax, legal, or investment advice. Every downstream artifact that references this fork must carry a linked, executed copy of the operator's confirmed fork state, hash-anchored to `ReserveProofAnchor` before it is used in any subscription document or lender package.*
