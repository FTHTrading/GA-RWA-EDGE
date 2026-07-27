#!/usr/bin/env python3
"""GA-EDGE-2 P0 calculator suite — deterministic, integer-first, audit-friendly.

Implements the Phase-1/2 internal build set:
  qrof        QROF / OZ 2.0 step-up + tax savings
  itc         ITC §48E + basis reduction + MACRS(+bonus) schedule
  trex        Tax-equity (partnership flip) sizing
  stack       PPA-aware capital stack + DSCR sensitivity
  pod         Modular pod sizing + PUE/cooling
  carbon      Carbon intensity & avoided emissions
  payload     ReserveProofAnchor / attestation payload builder

All money in integer cents unless noted. Formulas mirror docs/tax-esg-formulas.md
(GA-RWA-EDGE). NOT tax advice — CPA/counsel validate before any investor use.
Run: python3 calculators.py demo   (worked 3 MW pod example end-to-end)
"""
import argparse, hashlib, json, sys

# ---------- 1. QROF / OZ 2.0 ----------

def qrof_stepup(deferred_gain_cents: int, rural: bool, tax_rate_bps: int = 2380):
    """Standard: 5-yr deferral + 10% step-up. Rural QROF: 30%. 10-yr hold: appreciation tax-free."""
    stepup_bps = 3000 if rural else 1000
    stepup = deferred_gain_cents * stepup_bps // 10_000
    taxable_at_recognition = deferred_gain_cents - stepup
    tax_no_oz = deferred_gain_cents * tax_rate_bps // 10_000
    tax_with_oz = taxable_at_recognition * tax_rate_bps // 10_000
    return {
        "deferredGainCents": deferred_gain_cents,
        "tier": "RURAL_QROF_30" if rural else "STANDARD_10",
        "basisStepUpCents": stepup,
        "taxableAtYear5Cents": taxable_at_recognition,
        "taxSavingsVsNoOZCents": tax_no_oz - tax_with_oz,
        "note": "10-yr hold => post-investment appreciation excluded (FMV basis reset); deferral is rolling 5-yr (OBBBA)",
    }

# ---------- 2. ITC + MACRS ----------

MACRS_5YR_BPS = [2000, 3200, 1920, 1152, 1152, 576]   # half-year convention
MACRS_7YR_BPS = [1429, 2449, 1749, 1249, 893, 892, 893, 446]

def itc_macrs(eligible_basis_cents: int, itc_rate_bps: int = 3000,
              domestic_content: bool = False, energy_community: bool = False,
              bonus_depr_bps: int = 10_000, tax_rate_bps: int = 2100,
              macrs_class: int = 5):
    """§48E ITC + adders; depreciable basis reduced by 50% of ITC; MACRS w/ optional bonus.
    bonus_depr_bps=10_000 => 100% bonus (year-1). Placed-in-service deadline 2027-12-31 (OBBBA)."""
    rate = itc_rate_bps + (1000 if domestic_content else 0) + (1000 if energy_community else 0)
    itc = eligible_basis_cents * rate // 10_000
    depr_basis = eligible_basis_cents - itc // 2  # basis reduction = 50% of ITC
    table = MACRS_5YR_BPS if macrs_class == 5 else MACRS_7YR_BPS
    bonus = depr_basis * bonus_depr_bps // 10_000
    remaining = depr_basis - bonus
    schedule = []
    for i, bps in enumerate(table):
        amt = remaining * bps // 10_000
        if i == 0:
            amt += bonus
        schedule.append(amt)
    # assign rounding dust to final year (conservation)
    dust = depr_basis - sum(schedule)
    schedule[-1] += dust
    return {
        "itcRateBpsTotal": rate,
        "itcCents": itc,
        "depreciableBasisCents": depr_basis,
        "bonusYear1Cents": bonus,
        "macrsScheduleCents": schedule,
        "year1TotalDeductionCents": schedule[0],
        "npvTaxShieldApproxCents": sum(schedule) * tax_rate_bps // 10_000,
        "deadline": "placed-in-service 2027-12-31 (OBBBA)",
    }

# ---------- 3. TREX / tax-equity sizing ----------

def trex_sizing(itc_cents: int, year1_depr_cents: int, tax_rate_bps: int = 2100,
                sizing_low_bps: int = 10_000, sizing_high_bps: int = 13_000,
                target_irr_bps_low: int = 750, target_irr_bps_high: int = 950):
    """Rule-of-thumb sizing (1.0x-1.3x ITC) + benefit stack. Full period model runs in the
    tax-equity-itc-flips flow (99/1 pre-flip -> 5/95 post-flip at target after-tax IRR)."""
    return {
        "checkLowCents": itc_cents * sizing_low_bps // 10_000,
        "checkHighCents": itc_cents * sizing_high_bps // 10_000,
        "year1TaxBenefitToInvestorCents": (itc_cents + year1_depr_cents * tax_rate_bps // 10_000) * 99 // 100,
        "flipStructure": "99/1 -> 5/95 on after-tax IRR target",
        "targetAfterTaxIrrBps": [target_irr_bps_low, target_irr_bps_high],
        "note": "sponsor buyout option at flip typically FMV of residual 5%",
    }

# ---------- 4. Capital stack + DSCR (PPA-aware) ----------

def capital_stack(total_cost_cents: int, ppa_score_0_24: int,
                  hosting_rev_annual_cents: int, opex_annual_cents: int,
                  demand_charges_annual_cents: int, senior_rate_bps: int,
                  amort_years: int, itc_equity_cents: int = 0, qrof_equity_cents: int = 0):
    """Senior advance rate scales with PPA diligence score (55%..75%). DSCR tested NET of
    PPA demand charges (they behave like senior-to-everything opex)."""
    if ppa_score_0_24 < 12:
        advance_bps = 0  # unfinanceable PPA
    else:
        advance_bps = 5500 + (ppa_score_0_24 - 12) * 2000 // 12  # 55% at 12 -> 75% at 24
    senior = total_cost_cents * advance_bps // 10_000
    # mortgage-style annual debt service on bps rate (integer approximation)
    r = senior_rate_bps
    if r == 0:
        ds = senior // amort_years
    else:
        # annuity factor scaled 1e6: r/(1-(1+r)^-n) computed with float then applied to int (documented approximation)
        rf = r / 10_000
        factor = rf / (1 - (1 + rf) ** (-amort_years))
        ds = int(senior * factor)
    noi_net = hosting_rev_annual_cents - opex_annual_cents - demand_charges_annual_cents
    dscr_bps = noi_net * 10_000 // ds if ds else 0
    gap = total_cost_cents - senior - itc_equity_cents - qrof_equity_cents
    return {
        "ppaScore": ppa_score_0_24,
        "seniorAdvanceBps": advance_bps,
        "seniorCents": senior,
        "annualDebtServiceCents": ds,
        "noiNetOfDemandChargesCents": noi_net,
        "dscrBps": dscr_bps,
        "dscrGates": {"cashTrap": 12_000, "turbo": 11_000, "underwriteMin": 12_500},
        "itcTaxEquityCents": itc_equity_cents,
        "qrofEquityCents": qrof_equity_cents,
        "remainingEquityGapCents": gap,
        "verdict": "PASS" if dscr_bps >= 12_500 and gap <= 0 else ("DSCR_FAIL" if dscr_bps < 12_500 else "EQUITY_GAP"),
    }

# ---------- 5. Pod sizing / PUE ----------

def pod_sizing(target_it_mw_milli: int, pod_it_kw: int = 1000, pue_centi: int = 108,
               immersion: bool = True):
    """target_it_mw_milli: IT load in milli-MW (3_000 = 3 MW). PUE in centi (108 = 1.08)."""
    it_kw = target_it_mw_milli
    pods = -(-it_kw // pod_it_kw)  # ceil
    total_facility_kw = it_kw * pue_centi // 100
    cooling_kw = total_facility_kw - it_kw
    tons_cooling = cooling_kw * 100 // 352  # 1 ton ~= 3.52 kW
    return {
        "itLoadKw": it_kw, "podUnitKw": pod_it_kw, "podCount": pods,
        "pueCenti": pue_centi, "cooling": "liquid-immersion" if immersion else "air",
        "totalFacilityKw": total_facility_kw, "coolingLoadKw": cooling_kw,
        "coolingTons": tons_cooling,
        "note": "immersion PUE band 1.03-1.10; air 1.3-1.6; utility load letter should cover totalFacilityKw + 20% margin",
    }

# ---------- 6. Carbon intensity ----------

EMISSION_FACTORS_KG_PER_MWH = {"grid_serc": 380, "solar_onsite": 0, "gas_recip": 500, "flared_gas_avoided": -250}

def carbon_intensity(mwh_by_source: dict):
    """kg CO2e per MWh IT load, by attested source mix. Factors are planning-grade —
    replace with current eGRID/vendor factors at reporting time (attested)."""
    total_mwh = sum(mwh_by_source.values())
    total_kg = sum(EMISSION_FACTORS_KG_PER_MWH.get(src, 400) * mwh for src, mwh in mwh_by_source.items())
    return {
        "mix": mwh_by_source, "totalMwh": total_mwh, "totalKgCO2e": total_kg,
        "intensityKgPerMwh": (total_kg // total_mwh) if total_mwh else 0,
        "factorsUsed": EMISSION_FACTORS_KG_PER_MWH,
    }

# ---------- 7. ReserveProofAnchor payload builder ----------

def anchor_payload(deal_id: str, doc_type: str, file_path: str = None, content: bytes = None,
                   uri: str = "", metadata: str = ""):
    """Builds the exact anchorDocument() payload. docType must be one of the schema set."""
    allowed = {"PPA","EPC_SCOPE","EPC_FAT","EPC_SAT","EPC_IST","REVENUE","SREC","GAS",
               "CARBON_RETIREMENT","APPRAISAL","ZONING_LETTER","LOAD_LETTER"}
    if doc_type not in allowed:
        raise ValueError(f"docType {doc_type} not in schema set {sorted(allowed)}")
    data = content if content is not None else open(file_path, "rb").read()
    return {
        "dealId": "0x" + hashlib.sha3_256(deal_id.encode()).hexdigest(),  # note: use keccak256 on-chain side
        "docType": doc_type,
        "contentHash": "0x" + hashlib.sha256(data).hexdigest(),
        "uri": uri, "metadata": metadata,
        "call": "ReserveProofAnchor.anchorDocument(dealId, docType, contentHash, uri, metadata)",
    }

# ---------- demo: 3 MW rural pod, end to end ----------

def demo():
    d = {}
    d["1_pod"] = pod_sizing(3_000)  # 3 MW IT
    total_cost = 9_000_000_00  # $9.0M at $3.0M/MW (placeholder — replace w/ vendor quote)
    d["2_itc"] = itc_macrs(int(total_cost * 0.35), domestic_content=True)  # solar+storage slice of cost
    d["3_trex"] = trex_sizing(d["2_itc"]["itcCents"], d["2_itc"]["year1TotalDeductionCents"])
    d["4_qrof"] = qrof_stepup(2_000_000_00, rural=True)  # $2M deferred gain into QROF
    d["5_stack"] = capital_stack(
        total_cost_cents=total_cost, ppa_score_0_24=21,
        hosting_rev_annual_cents=2_100_000_00, opex_annual_cents=650_000_00,
        demand_charges_annual_cents=280_000_00, senior_rate_bps=850, amort_years=15,
        itc_equity_cents=d["3_trex"]["checkLowCents"], qrof_equity_cents=2_000_000_00)
    d["6_carbon"] = carbon_intensity({"solar_onsite": 4_100, "grid_serc": 12_600, "gas_recip": 1_800})
    d["7_anchor"] = anchor_payload("GA-POD-COWETA-01", "PPA", content=b"executed-ppa-bytes", uri="ipfs://example")
    print(json.dumps(d, indent=2))

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cmd", choices=["demo"], help="run the worked 3 MW example")
    args = ap.parse_args()
    demo()
