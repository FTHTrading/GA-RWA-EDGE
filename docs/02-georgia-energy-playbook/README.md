# 🟩 Georgia Energy Playbook
Single source: config/georgia/energy-params.json. Verified July 2026.

## SREC / REC reality
Georgia has NO compliance RPS and NO SREC compliance market. GA RECs are Tier-1/Class-I certificates sold bilaterally or voluntarily (often to the pod's own hosting customer for green-compute claims). Registry: M-RETS or NAR serials, minted 1 REC / 1 MWh via the SRECModule flow. Pods sited in PJM states (VA, PA, OH, NJ, MD) earn compliance SRECs instead — screen per site.

## ITC status (OBBBA) — cutoff missed
Solar / wind ITC §48E begin-construction safe harbor **lapsed 2026-07-04** — cutoff missed. New solar / wind builds no longer qualify for §48E. **Do not underwrite solar / wind ITC into any capital stack.** Storage-only ITC survives through 2033 (begin-construction runway). 45Q carbon capture credits remain available. Geothermal PTC survives. Never underwrite the GA data-center sales-tax exemption (five active bills; pods are below its thresholds anyway).

## Gas hybrid rules
Allowed (gasHybridAllowed=true) but attestation is REQUIRED: every period's gas MMBtu consumed and gas-fired Wh generated must be quorum-attested (GasAttestation contract). Gas-fired MWh are NEVER REC-eligible. Carbon accounting (Scope 1) rides the same record. Hybrid without measurement is greenwash bait — structurally prevented.

## Power process
Sub-5 MW pods are standard C&I customers (GA PSC large-load tariff targets hyperscale). Sequence: utility/EMC load letter -> transformer lead time check -> metering spec (revenue-grade, oracle-attested) -> THEN land option. Power before land, always.

## Geography
Preferred counties: Coweta, Clayton, Jackson, Newton, Douglas, Carroll (screen ordinance text + get written zoning verification letter per site). Avoid: City of Atlanta (use-based DC ban, no size floor), DeKalb, Fayetteville, Palmetto. Rural QROF tracts = 30% step-up tier; designation cycle live now, zones effective 2027-01-01.
