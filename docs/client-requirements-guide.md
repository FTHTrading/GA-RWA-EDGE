# Client Requirements & Diligence Guide
## What we need from you, and what you should demand from us

For asset originators, sponsors, and investors engaging FTH Trading / LD Capital on modular edge-infrastructure and tokenized real-asset deals. Bring the items in Part A complete; hold us to every item in Part B.

## Part A — What we need from you (intake requirements)

### A1. Entity & ownership
- Formation documents (articles, operating agreement), EIN letter, good-standing certificate
- Full beneficial-ownership chart to natural persons (UBOs at 25%+, and control persons)
- Officer/authorized-signer list; W-9/W-8 as applicable
- Any existing SPE structure for the asset (or we form one — the borrower is always a single-asset SPE)

### A2. The asset / site
- Address, county, parcel ID(s), acreage; current title status (owned / under option / target)
- OZ tract ID if known (we verify against the 2027 designation cycle; rural status drives the 30% tier)
- Existing zoning classification + any correspondence with the county (we require a written zoning verification letter before capital moves)
- Environmental: any Phase I ESA, wetlands, floodplain knowledge

### A3. Power (the gating item — incomplete power data stops intake)
- Serving utility or EMC name and any existing account/service
- Requested load (kW) and timeline; status of any load letter or interconnection application
- Site voltage available, distance to nearest three-phase, known transformer constraints
- On-site generation plans (solar/storage/gas) and any interconnection filings

### A4. Offtake / revenue (for operating or pre-leased assets)
- Counterparty legal name + credit info (rating, or 2 years financials for unrated)
- Term, rate structure, escalators; ALL demand charges and pass-throughs (DSCR is tested net of them)
- Explicit statement of who owns environmental attributes (RECs/carbon) — silence is a defect
- Termination, cure, assignment, and SLA terms (executed copy hashed and anchored at intake)

### A5. Financials & capital
- Two years of financials for the sponsor entity (or personal financial statement for new entities)
- Project budget / sources-and-uses draft; any existing debt or liens on the asset
- For QROF investors: the capital-gain event date (the 180-day reinvestment window is calculated from it — bring the exact date, the gain amount, and your CPA's contact)
- Target raise, minimum check size, and any existing investor commitments

### A6. Timeline & approvals
- Required close date and why; construction/commissioning deadlines (ITC placed-in-service 2027-12-31 governs solar scope)
- Board/committee approvals required on your side, and who signs

## Part B — What you should demand from us (and from anyone in this industry)

Hold every platform, including ours, to these. A "no" on any item is disqualifying — that standard is why our answers are documented.

1. **Show me the code.** Contracts should be inspectable and, at deploy, published with verified addresses. Marketing sites describing systems that do not exist in a repository are the industry's #1 red flag.
2. **Who holds the keys?** Custody must be qualified (BitGo/Anchorage-class) and the model named. Ours: 2-of-3 where the client/tenant holds the backup key — the platform can never move funds alone. If a platform is sole custodian of your assets, it is a counterparty, not a service.
3. **Where does my money sit before close?** Subscriptions belong in bank/trust escrow — never in the platform's operating account. Fiat moves only through licensed rails.
4. **Are the fees explicit?** Every fee should be a named bps or dollar line (structuring, servicing, trading). Opaque spreads are fees you can't audit.
5. **Is anyone promising returns?** Guaranteed yields, "risk-free" structures, SBLC/bank-instrument "monetization," or up-front fees to "release" funding are fraud patterns. Walk away — from us too, if you ever hear them here.
6. **Who is licensed for what?** Issuers may sell their own securities under Reg D 506(c); anyone selling a third party's securities for compensation must be a registered broker-dealer. Verify on FINRA BrokerCheck.
7. **Are ESG claims registry-backed?** A REC or carbon credit without a tracking-registry serial is a story, not an asset. Our contracts refuse to mint without one — ask any competitor to show the same control.
8. **Is compliance a gate or a report?** Ask: can an unverified wallet receive tokens? Can a sanctioned party claim a distribution? The correct answer is that the transfer reverts — enforcement before movement, not review after.
9. **Can I reproduce the math?** Waterfall distributions should reconcile against an independent model to the cent. Ours ships in the repo (waterfall_model.py). Ask for the reconciliation, any period.
10. **What happens when it fails?** Ask for the DSCR triggers, the cash-trap mechanics, the loss-allocation order (who is written down first), and the recovery path for lost keys. If those answers aren't crisp, the downside was never engineered.

## Part C — Document-by-document: the specifics to read closely

- **PPM / offering memorandum:** risk factors specific to THIS asset (generic risk lists are a tell); use of proceeds to the dollar; conflicts section naming the intercompany fee spine; tax section saying "consult your advisor" (a PPM promising tax outcomes is defective).
- **Subscription agreement:** your accreditation verification method (506(c) requires verification, not a checkbox); wire instructions matching the named escrow bank exactly (verify by phone — wire fraud is the #1 practical risk to you).
- **Operating/LLC agreement of the SPE:** distribution waterfall matching the PPM; transfer restrictions matching the token rules; what requires investor consent.
- **The token itself:** which wallet standards are supported; the lockup (Rule 144) end date; how recovery works if you lose keys (governance-gated recovery to a re-verified wallet — not "gone forever," not "we can move it whenever").
- **EPC contract (construction deals):** the 12-clause review sheet is in this repo — every clause should have a PASS with initials; ask to see it.
- **Commissioning certificates:** FAT/SAT/IST signed and hash-anchored before milestone payments release; ask for the anchor transaction.

## Part D — Data room index (what a complete package from us contains)
1. SPE formation + good standing + UBO chart
2. Title/option agreement + zoning verification letter + load letter
3. Executed PPA/offtake + credit file (+ OSINT report if unrated)
4. Appraisal / STR (hospitality) or vendor quotes + pod specs (compute)
5. Sources & uses + capital stack + DSCR sensitivity (calculator outputs)
6. PPM + subscription + SPE operating agreement (counsel-issued)
7. Tax package: QROF documents, ITC eligibility memo, MACRS schedule (CPA-issued)
8. On-chain: contract addresses, anchor transactions for every document above, attestor identities
9. Insurance certificates + custody confirmation (model: 2-of-3, backup key holder named)
10. The 12-clause EPC review + commissioning certificates (as milestones complete)

*This guide is engineering and process documentation, not legal, tax, or investment advice. Licensed counsel, CPA, and registered professionals sign their respective items before any offer or sale.*
