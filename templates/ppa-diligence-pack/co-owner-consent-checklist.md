# CO-OWNER CONSENT CHECKLIST
## Four non-Barak co-owners · Barak/Brock Site acquisition

> **Purpose:** Confirm all five owners of record (Barak + four co-owners) have consented in writing to the sale of the operating assets and the assignment of the PPA to the Site SPE, and that no minority owner retains a right of first refusal, drag-along objection, or other blocking right that would frustrate closing.
>
> **Why this checklist exists:** Multi-owner mining assets are the single most common source of stalled closings in this asset class. One dissenting co-owner with a 10% membership interest and a right-of-first-refusal clause can freeze a signed PSA for 60-90 days or unwind it entirely. Every consent must be papered before the acquisition PSA is executed.
>
> **Delivery:** Signed consent forms + operating agreement excerpt (showing the consent standard) + hash-anchored on-chain records, referenced back into Phase 0 gate as `co_owner_signoff` = one of { ALL-SIGNED | N-OF-4-SIGNED | PENDING }.

---

## 1. Ownership structure to confirm

Before requesting consents, confirm the ownership stack. Do not assume "Barak + 4 others" means 20% each — verify actual %.

| Co-owner | Legal name | % ownership | Signature capacity | Address |
|---|---|---|---|---|
| Barak | ______ | ______ | ______ | ______ |
| Co-owner 1 | ______ | ______ | ______ | ______ |
| Co-owner 2 | ______ | ______ | ______ | ______ |
| Co-owner 3 | ______ | ______ | ______ | ______ |
| Co-owner 4 | ______ | ______ | ______ | ______ |
| **Total** | | **100%** | | |

If total ≠ 100%, halt. Ownership structure is misstated and PSA cannot close.

---

## 2. Operating agreement review

Obtain the current operating agreement (or partnership agreement) of the ownership entity. Read for:

- [ ] Consent standard for a sale of substantially all assets (majority? supermajority? unanimous?).
- [ ] Right of first refusal held by any co-owner.
- [ ] Drag-along or tag-along provisions.
- [ ] Restrictions on assigning the PPA (some agreements pledge specific contracts to specific members).
- [ ] Any buy-sell agreement triggering on change of control.
- [ ] Any pending or threatened litigation among the members.

Attach the relevant excerpts to this checklist.

**Common trap:** if the operating agreement was drafted informally by one of the co-owners (not through counsel), it may not clearly state the sale-consent threshold. In that case, **default to unanimous consent** for safety — one un-signed co-owner post-closing is grounds to unwind.

---

## 3. Per-co-owner consent form (repeat for each of the four)

For each of the four non-Barak co-owners, obtain a signed consent form with the following content. Do not accept email confirmations — signed hard copy (or DocuSign-executed) only.

---

### CO-OWNER CONSENT AND WAIVER
Ref: Sale of operating assets located at [Premise Address], Georgia and assignment of PPA Contract [PPA Contract Number]

I, ________________, holder of _____% of the membership interests in ________________ (the "Seller Entity"), consent to the following:

1. The sale by the Seller Entity of substantially all of the operating assets located at the Premise, including the modular mining containers, miner units, ancillary infrastructure (PDU, switchgear, transformers, security systems), and any related intangibles, to LD Capital LLC or its designated Site SPE.

2. The assignment of the Power Purchase Agreement identified above from the Seller Entity to the acquiring Site SPE, and the pledge or securitization of the receivable derived therefrom.

3. My waiver of any right of first refusal, tag-along, drag-along objection, or other blocking right under the Seller Entity's operating agreement that would frustrate consummation of the sale.

4. My acknowledgement that the sale price of $________ (and any adjustments per the PSA) constitutes fair consideration and I have no claim of appraisal, dissent, or objection based on price.

5. My representation that I am not aware of any lien, judgment, tax obligation, or other encumbrance held by me personally against the assets being sold.

Signed: __________________________  Date: _________
Name (print): __________________________
% Interest: _____
Witness: __________________________  Date: _________

---

## 4. Verification list

After obtaining all four consent forms:

- [ ] Confirm each signature is the co-owner's actual signature (compare to prior legal instruments if possible).
- [ ] Confirm the % interest cited on each form sums correctly with Barak's % to 100%.
- [ ] Confirm none of the four is a minor, incapacitated, or in an active bankruptcy.
- [ ] Confirm no co-owner is on any restricted-persons list (OFAC, PEP screen) — a screen through the Unykorn AML rail.
- [ ] Confirm no co-owner has assigned or pledged their membership interest to a third party (creditor, ex-spouse, etc.). Where uncertainty exists, request estoppel from that third party.

---

## 5. Common failure modes and how to resolve them

**Failure 1 — One co-owner is unresponsive.** Do not paper over. Halt the closing and either (a) buy out that co-owner's interest separately with an assignment of their block, (b) restructure the sale to exclude the assets tied to that co-owner, or (c) walk. Do not close and hope.

**Failure 2 — Co-owner demands a side payment.** Document any side agreement as an amendment to the PSA with full disclosure to the other co-owners. Side deals that aren't disclosed to the other members are grounds to unwind.

**Failure 3 — Operating agreement is missing / never executed.** Retreat: obtain a written affirmation from each co-owner of the ownership structure, the sale, and the price, and treat that written affirmation as the operating agreement for this transaction. Note the risk to LD Capital counsel.

**Failure 4 — Co-owner is in a divorce or estate proceeding.** Request estoppel from opposing counsel or the estate representative before closing. A signed consent from a co-owner whose interest is subject to a pending court order can be unwound by the court.

**Failure 5 — Consent conditional on a covenant LD Capital cannot deliver.** Note the covenant and evaluate whether the Site SPE can absorb it (e.g., preserving a co-owner's employment at the site). If yes, paper it. If no, walk.

---

## 6. Verdict for Phase 0 gate

- [ ] **ALL-SIGNED** — all four non-Barak co-owners have signed and delivered the Consent and Waiver, verification list passes, no failure mode applies.
- [ ] **N-OF-4-SIGNED** — fewer than four have signed. State which are outstanding and why.
- [ ] **PENDING** — consent forms sent but not yet returned.

Feed to Phase 0 gate as `co_owner_signoff`. Advance to Phase 1 is permitted at `ALL-SIGNED` only.

---

## 7. Post-audit

1. Compile all four signed consents + operating agreement excerpt into a single PDF.
2. SHA-256 hash the PDF.
3. `ReserveProofAnchor.anchorDocument(dealId, "COOWNER-CONSENT-<date>", sha256, uri)`.
4. Deliver signed PDF + on-chain receipt to LD Capital counsel and the Site SPE closing binder.
