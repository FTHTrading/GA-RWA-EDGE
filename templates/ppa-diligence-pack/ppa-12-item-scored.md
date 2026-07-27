# ⬛ PPA / Hosting Offtake — 12-Item Scored Diligence (Go/No-Go)
Score each 0-2 (0=fail, 1=conditional, 2=pass). GO requires >= 20/24 AND no zero on items 1-4.

1. COUNTERPARTY CREDIT — rated or 2yr financials; unrated -> forensic-osint-audit report attached.
2. TERM >= DEBT TENOR — offtake term covers senior amortization or has lender-acceptable renewal.
3. PRICING — fixed rate or floored; escalators defined; demand charges explicit (DSCR is tested NET of them).
4. ATTRIBUTE OWNERSHIP — RECs/carbon attributes EXPLICITLY owned by the SPE (default) or priced separately.
5. DELIVERY POINT & INTERCONNECT — responsibility matrix; utility feed named; metering spec (revenue-grade).
6. FIRMNESS / CURTAILMENT — take-or-pay floor %, curtailment compensation.
7. SLA & REMEDIES — uptime %, credits schedule, cap on credits.
8. TERMINATION & CURE — cure periods; termination payments; no naked convenience-termination by offtaker.
9. ASSIGNMENT / NOVATION — assignable to SPE and collaterally to lender; novation mechanics pre-agreed.
10. INSURANCE & LIABILITY — caps, consequential-damage waiver mutual.
11. REGULATORY — no MTL/utility-resale trap (hosting fee structure, not retail electricity sale).
12. DOC INTEGRITY — executed copy hashed + anchored: ReserveProofAnchor.anchorDocument(dealId,"PPA",sha256,uri).
