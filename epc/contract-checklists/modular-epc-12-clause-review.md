# 🟧 Modular EPC Contract — 12-Clause Review (counsel + PM sign each)
Each clause: PASS / FLAG / FAIL + reviewer initials + date. FAIL on any of 1,2,5,8 = do not execute.

1. SCOPE & DESIGN BASIS — pod count/MW, immersion spec, exclusions listed; design-basis doc referenced by hash (anchor as docType "EPC_SCOPE").
2. PRICE & PAYMENT MILESTONES — fixed price or GMP; milestone schedule matches draw escrow; retainage 5-10%; NO payment without lien waiver (atomic draw-for-waiver).
3. SCHEDULE & LDs — commissioning date vs ITC placed-in-service deadline (2027-12-31) with buffer >= 90 days; liquidated damages per day; force majeure carve-outs bounded.
4. PERFORMANCE GUARANTEES — nameplate kW, PUE ceiling (immersion <= 1.10), uptime at handover; measured at IST by revenue-grade meters (oracle-attested).
5. FAT / SAT / IST GATES — factory, site, integrated system tests each produce a certificate (templates/commissioning-certificates/) anchored on-chain before the linked milestone pays.
6. WARRANTIES — pods >= 2yr, power electronics >= 5yr, workmanship >= 1yr; pass-through of OEM warranties; remedy timelines.
7. CHANGE ORDERS — written-only, priced from unit-rate schedule, cumulative cap (e.g. 10%) before re-approval by CustodyAdapter 4-eyes.
8. LIEN WAIVERS & TITLE — conditional waiver with each payment, unconditional on receipt; title to equipment passes at payment WITH UCC-1 by senior lender acknowledged.
9. INSURANCE & INDEMNITY — builder's risk, CGL, professional; SPE + lender as additional insureds; mutual indemnity capped.
10. SUSPENSION / TERMINATION — owner termination for convenience with capped breakage; EPC termination only on extended non-payment; step-in rights for the LENDER (required by senior).
11. DISPUTES — escalation ladder -> mediation -> arbitration (seat: Georgia); continued performance during dispute.
12. ASSIGNMENT & COLLATERAL — contract assignable to SPE + collaterally to senior lender WITHOUT consent friction; EPC may not assign without owner consent.
