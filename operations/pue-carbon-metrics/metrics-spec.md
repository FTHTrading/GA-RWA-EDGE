# 🟥 Operational Metrics Spec
PUE: target <= 1.15 site-wide; immersion pods 1.03-1.10. Measured = total facility kWh / IT kWh, monthly, meter-attested.
Carbon intensity: kgCO2e per MWh IT load, split by source (grid GA avg ~ published eGRID SERC value | on-site solar 0 | gas per attested MMBtu x emission factor). Publish monthly to ReserveProofAnchor as docType "REVENUE" attachment or dedicated dashboard feed.
DSCR feed (operations/dscr-feeds/): dscrBps = hostingNOI_period x 10000 / debtService_period, NET of PPA demand charges; pushed by servicer with the waterfall signal. Thresholds: cash-trap < 12000, turbo < 11000, 2-period hysteresis.
