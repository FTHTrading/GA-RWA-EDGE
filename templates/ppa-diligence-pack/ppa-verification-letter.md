# PPA VERIFICATION LETTER — TEMPLATE
## To the power provider and seller's counsel · Barak/Brock Site · Georgia 10 MW PPA

> **Purpose:** Confirm PPA status, assignability to the Site SPE, and pledgeability of the receivable to a securitization vehicle. Three separate confirmations must come back written and executable before Phase 4 tokenization can be committed to a subscription document.
>
> **How to use:** Fill the bracketed fields. Send under LD Capital LLC letterhead through counsel of record. Do not modify the questions section — the exact wording of each question is what makes the response actionable in a subsequent Reg D 506(c) filing.

---

**LD CAPITAL LLC**
[Street Address]
[City, State ZIP]

Date: [DATE]

To: [Power Provider Name — legal entity]
    Attn: [Regulatory / Contracts Counsel Name, Title]
    [Address]

Cc: [Seller's Counsel — legal entity, address]
    [Site owner-of-record — legal entity, address]

**Re: Power Purchase Agreement dated [PPA EFFECTIVE DATE] between [Original Buyer] and [Power Provider] for the premise located at [Site Street Address], Georgia (the "Premise"); Contract Reference [PPA CONTRACT NUMBER] (the "PPA").**

---

Counsel:

LD Capital LLC ("LD Capital") is negotiating the acquisition of the operating assets located at the Premise, including the assumption of the PPA identified above. This letter requests written confirmation of the PPA's current status, assignability, and pledgeability, as follows.

Any incoming acquisition capital, including the equity to be raised for the Site SPE, will be dependent on your written responses to the questions below. Because the acquisition documents and the subsequent tokenization vehicle will be Reg D 506(c) securities offerings, any factual claim by LD Capital regarding the PPA must trace to a signed statement from you.

Please respond within [10 business days] to enable a closing on or before [TARGET CLOSE DATE].

---

## Section A — PPA current status

Please confirm each of the following in writing (yes / no / with qualification):

**A.1** As of the date of your response, the PPA remains in force between [Power Provider] and [Original Buyer], and has not been terminated, suspended, force-majeured, or amended in any way not reflected in the executed copy attached as Exhibit 1.

**A.2** All amounts owed by [Original Buyer] under the PPA are current as of the date of your response. If arrears exist, please state the current arrears balance in U.S. dollars.

**A.3** Power is currently being delivered to the Premise under the PPA. If not, please state:
- the date service was suspended or reduced,
- the reason (dormancy, non-payment, curtailment, other),
- whether service can be reactivated under the existing PPA terms without renegotiation, and
- the reactivation charges (reconnection fee, deposit, arrears, other) that would apply.

**A.4** If service has been suspended, please confirm that the PPA has not lapsed by operation of any dormancy or non-use clause.

---

## Section B — Assignability of the PPA to the Site SPE

**B.1** LD Capital intends to assign the PPA at closing from [Original Buyer] to a Georgia limited liability company (the "Site SPE") organized specifically to own the operating assets. Please confirm whether such assignment requires:
- (a) written consent of the Power Provider, and
- (b) any regulatory approval (Georgia Public Service Commission, Georgia Power Territorial approval, or other).

**B.2** If consent to assign is required, please state:
- the standard for granting consent (reasonableness, sole discretion, other),
- any conditions typically attached (credit support, guaranty, deposit),
- the fee schedule for processing the consent, and
- the typical processing time.

**B.3** Please confirm that assignment of the PPA to the Site SPE will not:
- (a) trigger any rate reset, tariff reclassification, or loss of grandfathered pricing,
- (b) trigger any cure period or default under the PPA, and
- (c) reduce the remaining term of the PPA.

---

## Section C — Pledgeability of the PPA receivable

**This section is critical and often overlooked.** Assignability to the Site SPE (Section B) and pledgeability of the receivable (this Section C) are two separate consents. Please answer this section separately.

**C.1** After assignment of the PPA to the Site SPE, LD Capital intends to structure a securitization vehicle (an on-chain permissioned-security vault under Reg D 506(c)) that will:
- receive the cash-flow stream derived from the Site SPE's operations under the PPA, and/or
- take a security interest in the receivable owed to the Site SPE under the PPA.

Please confirm whether:
- (a) such pledge / assignment of the receivable requires separate written consent, and
- (b) if so, the standard, conditions, fee, and processing time for that consent.

**C.2** Please confirm that:
- (a) the PPA does not contain any anti-assignment-of-receivable clause that would frustrate a lien perfected on the receivable,
- (b) upon proper UCC-1 filing and notice, the Power Provider will honor a request from the Site SPE to direct payments to a designated deposit or on-chain settlement address, and
- (c) no acceptance of such re-routing would constitute a default or trigger a change-of-control provision under the PPA.

**C.3** If the Power Provider requires a formal Consent to Assignment of Receivable (a "CAR" agreement), please provide your standard form so that LD Capital may pre-negotiate it before the closing of the acquisition.

---

## Section D — Large-load carve-out and competitive-supply questions

**D.1** LD Capital understands that under the Georgia Territorial Electric Service Act (O.C.G.A. § 46-3-1 et seq.), new premises drawing above 900 kW may choose their electricity supplier at initial connection. Please confirm whether the Premise:
- (a) qualifies for the large-load carve-out under the Act,
- (b) has any grandfathering that would prevent supplier choice, and
- (c) has been the subject of any Georgia PSC action that would restrict competitive supply.

**D.2** If the large-load carve-out applies, please describe the process for the Site SPE to designate a competitive retail supplier post-closing, and any impact on the current PPA pricing.

---

## Section E — Attachments requested from you

Please attach with your response:

1. Executed copy of the PPA and all amendments.
2. Any recent (last 6 months) invoices from you to the current PPA counterparty.
3. If service has been suspended, the notice(s) of suspension and any correspondence regarding reactivation.
4. Your standard Consent-to-Assignment agreement.
5. Your standard Consent-to-Assignment-of-Receivable agreement (if separate).
6. Any Georgia PSC filings referencing the Premise or the PPA.

---

## Signature block

Respectfully,

_____________________________________
[NAME], [TITLE]
LD Capital LLC

Counsel of record: [Firm], [Attorney Name]

---

## Internal note (do not send)

The response to this letter must be hash-anchored via `ReserveProofAnchor.anchorDocument(dealId, "PPA-VERIFICATION-RESP-<date>", sha256, uri)` on receipt. The three critical returns — Section A.1 (in force?), Section B.1 (assignable to SPE?), Section C.1 (pledgeable?) — feed directly into the Phase 0 gates:

- Section A.1 → `ppa_status`
- Section B.1 → `assignment_consent_required`
- Section C.1 → `consent_to_pledge_or_assign_receivable`  **← the gate that most operators forget until Phase 4 stalls.**
- Section D.1 → `large_load_carve_out_applies_to_site`

The Phase 0 diligence gate cannot pass without all four returns confirmed in writing.
