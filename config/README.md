# 🟧 Configuration

Georgia-specific and deal-specific configuration seeds. Consumed by `GeorgiaEnergyAgent`, front-end site-selection tooling, and CPA / OZ counsel worksheets.

## Files

```text
georgia/energy-params.json    Utility pathways · PSC large-load rule · sales-tax exemption + 5
                              attacking bills · OBBBA ITC/PTC/45Q/45V rules and deadlines
                              (solar begin-construction 7/4/26 lapse + placed-in-service
                              12/31/27, storage runway to 2033).

georgia/zoning-matrix.json    18 metro-area jurisdictions ranked NO / YES_WITH_LETTER / BEST.
                              City of Atlanta / DeKalb / Fayetteville / Palmetto = NO.
                              Coweta / Clayton / Jackson / Newton / rural counties = BEST.
                              Urbanized-area caveat baked in as a field.

georgia/rural-tracts.json     OZ 2.0 nomination window (closes Sept 29, 2026 → effective
                              Jan 1, 2027). Primary Path B tract candidates (White / Jackson
                              / Carroll outer), backup secondary, border-state expansion
                              (TVA / VA / SC).
```

## Critical: statutory rural definition

Under IRC §1400Z-2 as amended by OBBBA (signed July 4, 2025), a **rural area** = any area other than:

1. A city or town with population greater than 50,000, **and**
2. Any Census-defined **urbanized area contiguous and adjacent** to such a city or town.

Both prongs must clear. **Per-tract test, not per-county.**

Many tracts that "feel rural" fail this test because the Atlanta urbanized area extends far into the surrounding counties. Verify every candidate tract against the certified 2027 QOZ map AND the Census urbanized-area boundary for Atlanta / Marietta before any option is signed.

## Adding a new deal config

For each new deal, create `deals/<deal-id>/params.json` with:

- Delivery-point / substation identifier
- Tract IDs (primary + backup)
- Zoning-verification letter status
- Waterfall priority customization
- Barak (or other originator) compensation blend
- Solar co-location scale + ITC eligibility flag

The config is consumed by `DealOnboardingAgent` and hashed into `DealRegistry` at SPE spin-up.
