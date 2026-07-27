#!/usr/bin/env python3
"""GA-RWA-EDGE calculator suite — deterministic, integer-first, audit-friendly.

Implements the full P0/P1 internal build queue documented in
docs/09-calculators/inventory.md.

TAX & INCENTIVES
  qrof              QROF / OZ 2.0 step-up + tax savings
  itc               ITC §48E + basis reduction + MACRS(+bonus) schedule
  section179        Section 179 expensing with 2026 phase-out
  tax_stacker       Combined QROF + ITC + MACRS + §179 in one call

TAX EQUITY (TREX)
  trex_sizing       Rule-of-thumb sizing (1.0x-1.3x ITC)
  partnership_flip  Full 99/1 -> 5/95 flip with year-by-year cashflow

CAPITAL STACK & UNDERWRITING
  capital_stack     PPA-aware capital stack + DSCR sensitivity
  dscr_ppa_aware    Standalone DSCR tested NET of PPA demand charges
  senior_ltv        Senior advance-rate sensitivity by PPA score

TECHNICAL / INFRASTRUCTURE
  pod_sizing        Modular pod sizing + PUE/cooling
  pue_cooling       PUE + cooling load + tonnage selection
  site_scorecard    Standardized site intake (power/cooling/conn/security/certs)
  interconnect      Delivery-point feasibility (voltage/firmness/diversity)

ESG / CARBON / SREC
  carbon_intensity  kg CO2e per MWh IT load by attested source mix
  srec_revenue      MWh -> REC volume -> $ (GA voluntary vs PJM compliance)

DEAL SETUP / OPERATIONAL
  ppa_scorer        12-item Go/No-Go scoring (auto-verdict)
  rural_qrof        GA rural QROF screener (city + urbanized-area tests)
  anchor_payload    ReserveProofAnchor / attestation payload builder

All money in integer cents unless noted. Formulas mirror
docs/02-tax-esg-incentives/formulas.md. NOT tax advice — CPA/counsel
validate before any investor use.

Run: python3 calculators.py demo   (worked Barak 5 MW example, 4.9c/kWh PPA)
"""
import argparse, hashlib, json, sys

# =========================================================================
# 1. QROF / OZ 2.0
# =========================================================================

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

# =========================================================================
# 2. ITC + MACRS
# =========================================================================

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

# =========================================================================
# 3. Section 179 (2026 limits per Rev. Proc. 2025-32)
# =========================================================================

SEC179_MAX_CENTS = 2_560_000_00
SEC179_PHASEOUT_START_CENTS = 4_090_000_00
SEC179_FULLY_PHASED_OUT_CENTS = 6_650_000_00

def section179(qualifying_property_cents: int, taxable_income_cents: int = None):
    """§179 immediate expensing after 2026 phase-out.
    Cap $2.56M, phase-out $1-for-$1 above $4.09M, zero at $6.65M.
    Constrained by taxable income from active trade/business (excess carries forward)."""
    if qualifying_property_cents <= SEC179_PHASEOUT_START_CENTS:
        allowed = SEC179_MAX_CENTS
    elif qualifying_property_cents >= SEC179_FULLY_PHASED_OUT_CENTS:
        allowed = 0
    else:
        excess = qualifying_property_cents - SEC179_PHASEOUT_START_CENTS
        allowed = max(0, SEC179_MAX_CENTS - excess)
    # capped further by qualifying property itself (can't §179 more than you bought)
    allowed = min(allowed, qualifying_property_cents)
    if taxable_income_cents is not None:
        actual = min(allowed, taxable_income_cents)
        carryforward = allowed - actual
    else:
        actual, carryforward = allowed, 0
    return {
        "qualifyingPropertyCents": qualifying_property_cents,
        "maxAllowedCents": allowed,
        "actualDeductionCents": actual,
        "carryforwardCents": carryforward,
        "phaseOutTriggered": qualifying_property_cents > SEC179_PHASEOUT_START_CENTS,
        "fullyPhasedOut": qualifying_property_cents >= SEC179_FULLY_PHASED_OUT_CENTS,
        "note": "§179 applied FIRST -> then 100% bonus -> then regular MACRS. Subject to taxable-income limitation.",
    }

# =========================================================================
# 4. Combined Tax Benefit Stacker (QROF + ITC + MACRS + §179)
# =========================================================================

def tax_stacker(total_project_cents: int, deferred_gain_cents: int, rural_qrof: bool,
                itc_eligible_basis_cents: int, section179_property_cents: int,
                domestic_content: bool = True, energy_community: bool = False,
                tax_rate_bps: int = 2100, ltcg_niit_rate_bps: int = 2380):
    """Full stack: QROF step-up + ITC + MACRS(100% bonus) + §179 combined in one view.
    Returns per-layer benefit + Year-1 total + multi-year effective."""
    q = qrof_stepup(deferred_gain_cents, rural_qrof, ltcg_niit_rate_bps)
    i = itc_macrs(itc_eligible_basis_cents, domestic_content=domestic_content,
                  energy_community=energy_community, tax_rate_bps=tax_rate_bps)
    s = section179(section179_property_cents)
    year1_deductions = i["year1TotalDeductionCents"] + s["actualDeductionCents"]
    year1_tax_shield = year1_deductions * tax_rate_bps // 10_000
    year1_direct_credit = i["itcCents"]  # ITC is a dollar-for-dollar credit
    year1_total_benefit = year1_direct_credit + year1_tax_shield
    return {
        "qrof": q,
        "itc_macrs": i,
        "section179": s,
        "summary": {
            "year1DirectCreditCents": year1_direct_credit,
            "year1TaxShieldFromDeductionsCents": year1_tax_shield,
            "year1TotalTaxBenefitCents": year1_total_benefit,
            "multiYearTotalDeductionCents": sum(i["macrsScheduleCents"]) + s["actualDeductionCents"],
            "multiYearTaxShieldCents": i["npvTaxShieldApproxCents"] +
                                        s["actualDeductionCents"] * tax_rate_bps // 10_000,
            "qrofStepUpSavingsCents": q["taxSavingsVsNoOZCents"],
        },
        "note": "Order of application: §179 first -> 100% bonus -> regular MACRS. Depreciable basis already reduced by 50% ITC.",
    }

# =========================================================================
# 5. TREX / tax-equity sizing
# =========================================================================

def trex_sizing(itc_cents: int, year1_depr_cents: int, tax_rate_bps: int = 2100,
                sizing_low_bps: int = 10_000, sizing_high_bps: int = 13_000,
                target_irr_bps_low: int = 750, target_irr_bps_high: int = 950):
    """Rule-of-thumb sizing (1.0x-1.3x ITC) + benefit stack."""
    return {
        "checkLowCents": itc_cents * sizing_low_bps // 10_000,
        "checkHighCents": itc_cents * sizing_high_bps // 10_000,
        "year1TaxBenefitToInvestorCents": (itc_cents + year1_depr_cents * tax_rate_bps // 10_000) * 99 // 100,
        "flipStructure": "99/1 -> 5/95 on after-tax IRR target",
        "targetAfterTaxIrrBps": [target_irr_bps_low, target_irr_bps_high],
        "note": "sponsor buyout option at flip typically FMV of residual 5%",
    }

# =========================================================================
# 6. Partnership Flip Model (year-by-year)
# =========================================================================

def partnership_flip(itc_cents: int, macrs_schedule_cents: list, tax_rate_bps: int = 2100,
                     tax_equity_investment_cents: int = None, target_irr_bps: int = 850,
                     preflip_te_share_bps: int = 9900, postflip_te_share_bps: int = 500,
                     flip_trigger: str = "yield"):
    """Full partnership-flip cash flow model.
    Pre-flip: tax equity takes preflip_te_share (default 99%) of ITC + depreciation.
    Post-flip: drops to postflip_te_share (default 5%).
    Flip trigger: 'yield' (when TE hits target IRR) or 'date' (year 5-7 typical)."""
    if tax_equity_investment_cents is None:
        tax_equity_investment_cents = itc_cents * 11_500 // 10_000  # midpoint 1.15x
    preflip_te_bps = preflip_te_share_bps
    postflip_te_bps = postflip_te_share_bps
    itc_to_te = itc_cents * preflip_te_bps // 10_000  # all ITC in year 1 pre-flip
    cumulative_te_benefit = itc_to_te
    flip_year = None
    schedule = []
    for year, depr_cents in enumerate(macrs_schedule_cents, start=1):
        # allocation share
        te_share = preflip_te_bps if flip_year is None else postflip_te_bps
        te_depr = depr_cents * te_share // 10_000
        te_tax_shield = te_depr * tax_rate_bps // 10_000
        te_credit = itc_cents if year == 1 else 0
        te_benefit_year = te_tax_shield + (te_credit * te_share // 10_000 if year == 1 else 0)
        cumulative_te_benefit = cumulative_te_benefit + te_tax_shield if year > 1 else te_benefit_year
        # IRR proxy: cumulative benefit / investment
        te_pretax_return_bps = cumulative_te_benefit * 10_000 // tax_equity_investment_cents \
                               if tax_equity_investment_cents else 0
        # Flip trigger
        if flip_year is None:
            if flip_trigger == "yield" and te_pretax_return_bps >= target_irr_bps * year // 100:
                flip_year = year
            elif flip_trigger == "date" and year >= 5:
                flip_year = year
        schedule.append({
            "year": year,
            "teShareBps": te_share,
            "sponsorShareBps": 10_000 - te_share,
            "depreciationCents": depr_cents,
            "teDepreciationCents": te_depr,
            "teTaxShieldCents": te_tax_shield,
            "teCumulativeBenefitCents": cumulative_te_benefit,
            "flipped": flip_year is not None and year >= flip_year,
        })
    return {
        "taxEquityInvestmentCents": tax_equity_investment_cents,
        "sizingMultiple_x": tax_equity_investment_cents / itc_cents if itc_cents else 0,
        "flipYear": flip_year,
        "flipTrigger": flip_trigger,
        "targetIrrBps": target_irr_bps,
        "schedule": schedule,
        "note": "Simplified model — full IRR calc requires per-period cash distributions + tax + capital-account tracking. Use for scoping only.",
    }

# =========================================================================
# 7. Capital stack + DSCR (PPA-aware)
# =========================================================================

def senior_ltv(ppa_score_0_24: int):
    """Senior advance rate as function of PPA diligence score.
    <12 = unfinanceable; 12 = 55%; 24 = 75%."""
    if ppa_score_0_24 < 12:
        return {"advanceRateBps": 0, "verdict": "UNFINANCEABLE_PPA", "score": ppa_score_0_24}
    bps = 5500 + (ppa_score_0_24 - 12) * 2000 // 12
    return {"advanceRateBps": bps, "verdict": "FINANCEABLE", "score": ppa_score_0_24}

def dscr_ppa_aware(hosting_rev_annual_cents: int, opex_annual_cents: int,
                    demand_charges_annual_cents: int, annual_debt_service_cents: int):
    """DSCR tested NET of PPA demand charges — those behave like senior-to-everything opex."""
    noi_net = hosting_rev_annual_cents - opex_annual_cents - demand_charges_annual_cents
    dscr_bps = noi_net * 10_000 // annual_debt_service_cents if annual_debt_service_cents else 0
    gates = {
        "underwriteMin": 12_500,   # 1.25x
        "cashTrap": 12_000,        # 1.20x
        "turboAmort": 11_000,      # 1.10x
        "eventOfDefault": 10_000,  # 1.00x
    }
    if dscr_bps >= gates["underwriteMin"]:
        state = "PASS"
    elif dscr_bps >= gates["cashTrap"]:
        state = "PASS_CASH_TRAP"
    elif dscr_bps >= gates["turboAmort"]:
        state = "TURBO_AMORT"
    elif dscr_bps >= gates["eventOfDefault"]:
        state = "COVENANT_BREACH"
    else:
        state = "DEFAULT"
    return {
        "noiNetOfDemandChargesCents": noi_net,
        "annualDebtServiceCents": annual_debt_service_cents,
        "dscrBps": dscr_bps,
        "state": state,
        "gates": gates,
    }

def capital_stack(total_cost_cents: int, ppa_score_0_24: int,
                  hosting_rev_annual_cents: int, opex_annual_cents: int,
                  demand_charges_annual_cents: int, senior_rate_bps: int,
                  amort_years: int, itc_equity_cents: int = 0, qrof_equity_cents: int = 0,
                  equipment_debt_cents: int = 0, sponsor_equity_cents: int = 0):
    """Full source & uses builder. Senior advance rate scales with PPA diligence score."""
    ltv = senior_ltv(ppa_score_0_24)
    senior = total_cost_cents * ltv["advanceRateBps"] // 10_000
    if senior_rate_bps == 0:
        ds = senior // amort_years
    else:
        rf = senior_rate_bps / 10_000
        factor = rf / (1 - (1 + rf) ** (-amort_years))
        ds = int(senior * factor)
    dscr = dscr_ppa_aware(hosting_rev_annual_cents, opex_annual_cents,
                          demand_charges_annual_cents, ds)
    sources = senior + equipment_debt_cents + itc_equity_cents + qrof_equity_cents + sponsor_equity_cents
    gap = total_cost_cents - sources
    return {
        "uses": {"totalCostCents": total_cost_cents},
        "sources": {
            "seniorCents": senior,
            "seniorAdvanceBps": ltv["advanceRateBps"],
            "equipmentDebtCents": equipment_debt_cents,
            "itcTaxEquityCents": itc_equity_cents,
            "qrofEquityCents": qrof_equity_cents,
            "sponsorEquityCents": sponsor_equity_cents,
            "totalSourcesCents": sources,
        },
        "gapCents": gap,
        "annualDebtServiceCents": ds,
        "dscr": dscr,
        "verdict": "PASS" if dscr["state"] == "PASS" and gap <= 0 else
                   ("EQUITY_GAP" if gap > 0 else f"DSCR_{dscr['state']}"),
    }

# =========================================================================
# 8. Pod sizing + PUE / cooling
# =========================================================================

def pod_sizing(target_it_mw_milli: int, pod_it_kw: int = 1000, pue_centi: int = 108,
               immersion: bool = True):
    """target_it_mw_milli: IT load in milli-MW (3_000 = 3 MW). PUE in centi (108 = 1.08)."""
    it_kw = target_it_mw_milli
    pods = -(-it_kw // pod_it_kw)  # ceil
    total_facility_kw = it_kw * pue_centi // 100
    cooling_kw = total_facility_kw - it_kw
    tons_cooling = cooling_kw * 100 // 352
    return {
        "itLoadKw": it_kw, "podUnitKw": pod_it_kw, "podCount": pods,
        "pueCenti": pue_centi, "cooling": "liquid-immersion" if immersion else "air",
        "totalFacilityKw": total_facility_kw, "coolingLoadKw": cooling_kw,
        "coolingTons": tons_cooling,
        "note": "immersion PUE band 1.03-1.10; air 1.3-1.6; utility load letter should cover totalFacilityKw + 20% margin",
    }

def pue_cooling(it_load_kw: int, pue_centi: int = 108, ambient_deg_f: int = 95,
                redundancy: str = "N+1"):
    """PUE + cooling capacity + recommended cooling system.
    Recommends CRAC / In-Row / Chiller / Immersion based on rack density and PUE target."""
    facility_kw = it_load_kw * pue_centi // 100
    cooling_kw = facility_kw - it_load_kw
    tons = cooling_kw * 100 // 352
    # System selection heuristic
    if pue_centi <= 110:
        system = "single-phase immersion (Submer/GRC/LiquidStack/Iceotope)"
    elif pue_centi <= 130:
        system = "rear-door heat exchanger or in-row chilled water"
    elif pue_centi <= 150:
        system = "perimeter CRAC/CRAH with hot-aisle containment"
    else:
        system = "legacy CRAC — inefficient at scale"
    # Redundancy multiplier
    if redundancy == "N+1":
        installed_tons = tons + max(1, tons // 4)  # +25% or +1
    elif redundancy == "2N":
        installed_tons = tons * 2
    else:
        installed_tons = tons
    return {
        "itLoadKw": it_load_kw, "facilityKw": facility_kw, "coolingKw": cooling_kw,
        "designTonsRequired": tons, "installedTonsWithRedundancy": installed_tons,
        "recommendedSystem": system, "redundancyLevel": redundancy,
        "ambientDegF": ambient_deg_f,
        "note": "Design ambient GA metro ~95F; verify with local NOAA design-day data. Ductless liquid immersion is climate-agnostic.",
    }

# =========================================================================
# 9. Site Evaluation Scorecard (Canovate-pattern)
# =========================================================================

SITE_CRITERIA = {
    "power": ["firm_capacity_mw", "voltage_class", "feed_diversity", "utility_letter_status"],
    "cooling": ["water_source", "makeup_water_gpm", "climate_zone", "ambient_design_temp"],
    "connectivity": ["fiber_carriers_count", "latency_to_atl_ms", "ip_transit_available", "peering_options"],
    "security": ["perimeter_fence", "24_7_security", "camera_coverage_pct", "access_control_type"],
    "certifications": ["tier_target", "iso27001", "soc2", "sustainability_reporting"],
    "regulatory": ["zoning_letter_status", "oz_tract_id", "rural_flag", "psc_review_required"],
}

def site_scorecard(inputs: dict):
    """Standardized site intake. Inputs is a dict keyed by category -> subkey -> value.
    Returns scored intake (0-100) with category breakdowns + missing-field flags."""
    scores = {}
    missing = []
    for cat, subkeys in SITE_CRITERIA.items():
        cat_score = 0
        cat_max = 0
        for k in subkeys:
            key = f"{cat}.{k}"
            val = inputs.get(cat, {}).get(k)
            cat_max += 10
            if val is None or val == "":
                missing.append(key)
                continue
            # Scoring heuristic — real production version calibrates per-field
            if k == "firm_capacity_mw" and val >= 5:
                cat_score += 10
            elif k == "voltage_class" and val in ("46kV", "115kV", "230kV"):
                cat_score += 10
            elif k == "feed_diversity" and val >= 2:
                cat_score += 10
            elif k == "utility_letter_status" and val == "issued":
                cat_score += 10
            elif k == "fiber_carriers_count" and val >= 2:
                cat_score += 10
            elif k == "latency_to_atl_ms" and val <= 10:
                cat_score += 10
            elif k == "zoning_letter_status" and val == "issued":
                cat_score += 10
            elif k == "rural_flag" and val is True:
                cat_score += 10
            elif isinstance(val, (int, float)) and val > 0:
                cat_score += 6  # partial credit for numeric fields present
            else:
                cat_score += 5  # partial credit for presence
        scores[cat] = {"score": cat_score, "max": cat_max,
                       "percent": (cat_score * 100 // cat_max) if cat_max else 0}
    total = sum(s["score"] for s in scores.values())
    max_total = sum(s["max"] for s in scores.values())
    verdict = "PASS" if total * 100 // max_total >= 70 else \
              ("NEEDS_WORK" if total * 100 // max_total >= 50 else "FAIL")
    return {
        "scores": scores,
        "totalScore": total,
        "maxScore": max_total,
        "percentComplete": total * 100 // max_total if max_total else 0,
        "missingFields": missing,
        "verdict": verdict,
    }

# =========================================================================
# 10. Interconnect / Delivery-Point Feasibility
# =========================================================================

def interconnect(voltage_kv: int, firm_capacity_mw: int, target_load_mw: int,
                 feeds_count: int = 1, substation_distance_ft: int = 0,
                 utility_letter_issued: bool = False):
    """Delivery-point feasibility check. Returns pass/fail + specific gaps."""
    gaps = []
    if voltage_kv < 46:
        gaps.append(f"voltage_low: {voltage_kv}kV; commercial+ requires 46kV minimum for multi-MW load")
    if firm_capacity_mw < target_load_mw:
        gaps.append(f"capacity_short: firm {firm_capacity_mw}MW < target {target_load_mw}MW")
    if feeds_count < 2:
        gaps.append("single_feed: N+1 redundancy requires 2+ diverse feeds")
    if substation_distance_ft > 5000:
        gaps.append(f"substation_distance: {substation_distance_ft}ft; interconnect cost scales linearly")
    if not utility_letter_issued:
        gaps.append("no_utility_letter: intake blocked until issued")
    return {
        "voltageKv": voltage_kv,
        "firmCapacityMw": firm_capacity_mw,
        "targetLoadMw": target_load_mw,
        "feedsCount": feeds_count,
        "substationDistanceFt": substation_distance_ft,
        "utilityLetterIssued": utility_letter_issued,
        "gaps": gaps,
        "verdict": "PASS" if not gaps else ("BLOCK" if not utility_letter_issued else "CONDITIONAL"),
    }

# =========================================================================
# 11. Carbon intensity
# =========================================================================

EMISSION_FACTORS_KG_PER_MWH = {
    "grid_serc": 380,         # SERC grid mix (GA/AL/TN)
    "grid_pjm": 420,          # PJM RTO
    "solar_onsite": 0,
    "wind_ppa": 0,
    "gas_recip": 500,         # reciprocating engine
    "gas_turbine": 460,       # combustion turbine
    "flared_gas_avoided": -250,  # methane destruction credit (attested)
    "biogas_rng": 50,
}

def carbon_intensity(mwh_by_source: dict):
    """kg CO2e per MWh IT load, by attested source mix."""
    total_mwh = sum(mwh_by_source.values())
    total_kg = sum(EMISSION_FACTORS_KG_PER_MWH.get(src, 400) * mwh for src, mwh in mwh_by_source.items())
    return {
        "mix": mwh_by_source, "totalMwh": total_mwh, "totalKgCO2e": total_kg,
        "intensityKgPerMwh": (total_kg // total_mwh) if total_mwh else 0,
        "factorsUsed": EMISSION_FACTORS_KG_PER_MWH,
    }

# =========================================================================
# 12. SREC / REC revenue
# =========================================================================

def srec_revenue(annual_mwh: int, state: str, market: str = "voluntary",
                 voluntary_price_cents_per_mwh: int = 75,
                 premium_hourly_matched: bool = False):
    """MWh generation -> REC volume -> revenue estimate.
    market='voluntary' (GA reality) or 'compliance' (PJM states).
    voluntary_price_cents_per_mwh: generic national ~$0.30-$1.00/MWh -> use 75c (75 cents)."""
    rec_count = annual_mwh  # 1 REC = 1 MWh
    if market == "compliance":
        # PJM Tier I placeholder — real prices track SREC futures markets
        price_cents_per_mwh = 3_500_00 if premium_hourly_matched else 3_500_00  # ~$35/MWh
        note = "PJM Tier I compliance — track SREC futures (SREC2027, SREC2028 etc.)"
    else:
        if premium_hourly_matched:
            price_cents_per_mwh = 20_00  # $20/MWh premium hourly-matched
            note = "premium hourly-matched voluntary — corporate 24/7 CFE claims"
        else:
            price_cents_per_mwh = voluntary_price_cents_per_mwh
            note = "generic national unbundled voluntary REC"
    revenue_cents = rec_count * price_cents_per_mwh
    return {
        "state": state, "market": market, "recCount": rec_count,
        "pricePerMwhCents": price_cents_per_mwh, "annualRevenueCents": revenue_cents,
        "note": note,
    }

# =========================================================================
# 13. PPA Go/No-Go 12-item scorer
# =========================================================================

PPA_ITEMS = [
    "delivery_point", "term_length", "rate_structure", "capacity_firmness",
    "take_or_pay", "assignability", "counterparty_capacity", "site_use_restrictions",
    "environmental_attributes", "termination_triggers", "psc_review_posture", "novation_posture",
]
PPA_GO_NO_GO = {"delivery_point", "term_length", "assignability", "counterparty_capacity", "novation_posture"}

def ppa_scorer(scores: dict, notes: dict = None):
    """12-item PPA diligence scoring. Each item scored 0 (fail), 1 (partial), 2 (pass).
    Max score = 24. Any Go/No-Go item at 0 => BLOCK regardless of total."""
    notes = notes or {}
    total = 0
    breakdown = []
    hard_fail = []
    for item in PPA_ITEMS:
        s = scores.get(item, 0)
        s = max(0, min(2, int(s)))
        total += s
        breakdown.append({
            "item": item, "score": s, "note": notes.get(item, ""),
            "goNoGo": item in PPA_GO_NO_GO,
        })
        if item in PPA_GO_NO_GO and s == 0:
            hard_fail.append(item)
    if hard_fail:
        verdict = f"BLOCK: hard-fail on go/no-go items {hard_fail}"
    elif total >= 20:
        verdict = "PASS — proceed to senior lender teaser + PPM"
    elif total >= 16:
        verdict = "CONDITIONAL — remediate weak items before term sheet"
    else:
        verdict = "FAIL — deal restructures around a different anchor asset"
    return {
        "scoresRawByItem": scores,
        "totalScore": total, "maxScore": 24,
        "breakdown": breakdown,
        "hardFailItems": hard_fail,
        "verdict": verdict,
    }

# =========================================================================
# 14. GA Rural QROF Screener
# =========================================================================

def rural_qrof(tract_id: str, city_pop_over_50k_nearby: bool,
                inside_atlanta_urbanized_area: bool, oz2027_certified: bool,
                city_town_within_tract: str = ""):
    """Statutory rural test per IRC §1400Z-2 as amended by OBBBA:
    (i) NOT a city/town with pop > 50,000, AND
    (ii) NOT any Census-defined urbanized area contiguous and adjacent to such city/town.
    Both prongs must clear."""
    gates = []
    if city_pop_over_50k_nearby:
        gates.append("prong_i_fail: tract contains or is within city/town > 50k pop")
    if inside_atlanta_urbanized_area:
        gates.append("prong_ii_fail: inside Atlanta urbanized area (contiguous-adjacent to >50k city)")
    if not oz2027_certified:
        gates.append("map_pending: tract not certified on 2027 QOZ map (window closes Sept 29 2026)")
    if len(gates) == 0:
        tier = "RURAL_QROF_30_STEPUP"
        verdict = "PASS: rural QROF eligible — 30% basis step-up + 50% substantial-improvement threshold"
    elif inside_atlanta_urbanized_area or city_pop_over_50k_nearby:
        tier = "STANDARD_QOF_10_STEPUP" if oz2027_certified else "NOT_ELIGIBLE"
        verdict = "FALLBACK: standard QOF only (10% step-up)" if oz2027_certified else "FAIL: not OZ-eligible"
    else:
        tier = "PENDING_2027_CERT"
        verdict = "PENDING: awaiting 2027 map certification"
    return {
        "tractId": tract_id, "cityTownWithin": city_town_within_tract,
        "cityPopOver50kNearby": city_pop_over_50k_nearby,
        "insideAtlantaUrbanizedArea": inside_atlanta_urbanized_area,
        "oz2027Certified": oz2027_certified,
        "gates": gates, "tier": tier, "verdict": verdict,
    }

# =========================================================================
# 15. ReserveProofAnchor payload builder
# =========================================================================

def anchor_payload(deal_id: str, doc_type: str, file_path: str = None, content: bytes = None,
                   uri: str = "", metadata: str = ""):
    """Builds the exact anchorDocument() payload. docType must be one of the schema set."""
    allowed = {"PPA","EPC_SCOPE","EPC_FAT","EPC_SAT","EPC_IST","REVENUE","SREC","GAS",
               "CARBON_RETIREMENT","APPRAISAL","ZONING_LETTER","LOAD_LETTER"}
    if doc_type not in allowed:
        raise ValueError(f"docType {doc_type} not in schema set {sorted(allowed)}")
    data = content if content is not None else open(file_path, "rb").read()
    return {
        "dealId": "0x" + hashlib.sha3_256(deal_id.encode()).hexdigest(),
        "docType": doc_type,
        "contentHash": "0x" + hashlib.sha256(data).hexdigest(),
        "uri": uri, "metadata": metadata,
        "call": "ReserveProofAnchor.anchorDocument(dealId, docType, contentHash, uri, metadata)",
    }

# =========================================================================
# DEMO: Barak site — 5 MW existing, 4.9c/kWh PPA, 721 miners, deregulated gas zone
# =========================================================================

def demo():
    """Worked example against the actual Barak site facts:
      - 5 MW existing load (721 miners currently operating)
      - PPA rate: 4.9 cents/kWh
      - Deregulated gas zone (hybrid / expansion optionality)
      - Path B target: convert / supplement mining load with contracted AI hosting
    """
    d = {}

    # 1. Pod sizing at existing 5 MW IT load
    d["1_pod_sizing"] = pod_sizing(5_000, pue_centi=108, immersion=True)  # 5 MW = 5000 kW milli

    # 2. PUE / cooling deep-dive
    d["2_pue_cooling"] = pue_cooling(5_000, pue_centi=108, ambient_deg_f=95, redundancy="N+1")

    # 3. Interconnect feasibility for existing site
    d["3_interconnect"] = interconnect(
        voltage_kv=115, firm_capacity_mw=5, target_load_mw=5,
        feeds_count=1, substation_distance_ft=800, utility_letter_issued=True,
    )

    # 4. Annual PPA cost at 4.9c/kWh: 5000 kW * 8760 h * $0.049 = $2.146M/yr
    ppa_annual_cost_cents = 5_000 * 8760 * 49 // 10  # 4.9c in tenths, kWh
    print(f"\n[Barak site PPA annual cost @ 4.9c/kWh, 5 MW: ${ppa_annual_cost_cents/100/1e6:.2f}M]\n", file=sys.stderr)

    # 5. Project cost assumption — existing site conversion (not greenfield 20 MW)
    # Buy-out of miners + upgrade to AI hosting + immersion retrofit + solar+storage co-loc
    total_cost = 25_000_000_00  # $25M for conversion + expansion

    # 6. ITC on solar+storage slice (~$8M) — hits 12/31/27 in-service window
    d["4_itc_macrs"] = itc_macrs(int(total_cost * 0.32), domestic_content=True, energy_community=False)

    # 7. Section 179 on smaller equipment purchases
    d["5_section179"] = section179(6_000_000_00)  # $6M — inside phase-out band

    # 8. QROF step-up at $8M cap-gains rolled in
    d["6_qrof"] = qrof_stepup(8_000_000_00, rural=True)

    # 9. Combined tax stack
    d["7_tax_stack"] = tax_stacker(
        total_project_cents=total_cost,
        deferred_gain_cents=8_000_000_00,
        rural_qrof=True,
        itc_eligible_basis_cents=int(total_cost * 0.32),
        section179_property_cents=6_000_000_00,
        domestic_content=True,
    )

    # 10. TREX sizing + partnership flip
    d["8_trex"] = trex_sizing(d["4_itc_macrs"]["itcCents"], d["4_itc_macrs"]["year1TotalDeductionCents"])
    d["9_flip"] = partnership_flip(
        d["4_itc_macrs"]["itcCents"], d["4_itc_macrs"]["macrsScheduleCents"],
        tax_equity_investment_cents=d["8_trex"]["checkLowCents"],
    )

    # 11. Capital stack with PPA-aware DSCR
    # Hosting rev projection: $150/kW/month * 5000 kW * 12 = $9M/yr
    d["10_capital_stack"] = capital_stack(
        total_cost_cents=total_cost,
        ppa_score_0_24=22,  # 4.9c/kWh + delivery point known + firm 5 MW = high score
        hosting_rev_annual_cents=9_000_000_00,
        opex_annual_cents=800_000_00,
        demand_charges_annual_cents=ppa_annual_cost_cents,  # 4.9c power cost as opex-senior
        senior_rate_bps=850, amort_years=15,
        itc_equity_cents=d["8_trex"]["checkLowCents"],
        qrof_equity_cents=8_000_000_00,
        equipment_debt_cents=3_000_000_00,
        sponsor_equity_cents=2_000_000_00,
    )

    # 12. PPA scoring: 4.9c/kWh + deregulated gas zone = strong; assignability TBD
    d["11_ppa_score"] = ppa_scorer({
        "delivery_point": 2,        # known
        "term_length": 2,           # verify duration
        "rate_structure": 2,        # fixed 4.9c
        "capacity_firmness": 2,     # firm 5 MW
        "take_or_pay": 1,           # TBD
        "assignability": 1,         # verify — go/no-go
        "counterparty_capacity": 2, # Barak — verify entity authority
        "site_use_restrictions": 2, # existing miners suggest permissive
        "environmental_attributes": 1,
        "termination_triggers": 1,
        "psc_review_posture": 2,    # deregulated gas zone, sub-5 MW standard tariff
        "novation_posture": 1,      # go/no-go — verify utility posture
    }, notes={
        "rate_structure": "4.9 cents/kWh confirmed",
        "delivery_point": "existing operating site — utility letter effectively already issued via active load",
        "site_use_restrictions": "721 miners currently operating — no site-use restriction on data-center load",
    })

    # 13. Rural QROF screener — verify tract
    d["12_rural_qrof"] = rural_qrof(
        tract_id="TBD-verify-2027-map", city_pop_over_50k_nearby=False,
        inside_atlanta_urbanized_area=False, oz2027_certified=False,
        city_town_within_tract="TBD",
    )

    # 14. Carbon intensity — current mining load on grid; hybrid gas + solar future state
    d["13_carbon_current"] = carbon_intensity({"grid_serc": 43_800})  # 5 MW * 8760 hrs
    d["14_carbon_target"] = carbon_intensity({
        "solar_onsite": 8_760,          # 1 MW solar at 100% CF proxy
        "gas_recip": 8_760,             # 1 MW gas backup
        "grid_serc": 26_280,            # remaining grid draw
    })

    # 15. SREC revenue (voluntary GA + potential PJM if expansion)
    d["15_srec_ga_voluntary"] = srec_revenue(8_760, "GA", "voluntary")
    d["16_srec_va_compliance"] = srec_revenue(8_760, "VA", "compliance")

    # 16. Site scorecard
    d["17_site_scorecard"] = site_scorecard({
        "power": {"firm_capacity_mw": 5, "voltage_class": "115kV", "feed_diversity": 1,
                  "utility_letter_status": "issued"},
        "cooling": {"water_source": "well", "makeup_water_gpm": 25, "climate_zone": "GA_metro",
                    "ambient_design_temp": 95},
        "connectivity": {"fiber_carriers_count": 2, "latency_to_atl_ms": 8,
                         "ip_transit_available": True, "peering_options": "AT&T + Lumen"},
        "security": {"perimeter_fence": True, "24_7_security": False,
                     "camera_coverage_pct": 60, "access_control_type": "keypad"},
        "certifications": {"tier_target": "Tier_III", "iso27001": False, "soc2": False,
                           "sustainability_reporting": False},
        "regulatory": {"zoning_letter_status": "existing_use", "oz_tract_id": "TBD",
                       "rural_flag": None, "psc_review_required": False},
    })

    # 17. Anchor payloads for the deal
    d["18_anchor_ppa"] = anchor_payload("GA-BARAK-01", "PPA",
                                         content=b"executed-ppa-4.9c-5mw-bytes",
                                         uri="ipfs://TBD", metadata="term=TBD_yr,rate=4.9c,firm=5MW")

    print(json.dumps(d, indent=2, default=str))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cmd", choices=["demo"], help="run the Barak 5 MW example end-to-end")
    args = ap.parse_args()
    demo()
