# 🟪 Reserve-Proof & Attestation Schemas — exact hand-off to GA-RWA-EDGE
These formats match the DEPLOYED contract interfaces (unykorn-rwa/contracts). Do not improvise fields.

## Attestation struct (AttestationVerifier — EIP-712 domain "UnykornOracle"/"1")
{ "subject": "bytes32 keccak256(facilityId|dealId)", "claim": "bytes32 (see claims.json)",
  "value": "int256 integer minor units", "unit": "bytes32 (see claims.json)",
  "timestamp": "uint64 unix seconds of OBSERVATION", "nonce": "uint256 strictly increasing per signer x subject" }
Rules: m-of-n distinct allowlisted signers (default m=2); staleness window per feed; replayed nonce = revert; signer must persist nonce (a repeat bricks nothing but is rejected forever).

## Document anchors (ReserveProofAnchor.anchorDocument)
docType values (bytes32 short-strings): "PPA" | "EPC_SCOPE" | "EPC_FAT" | "EPC_SAT" | "EPC_IST" | "REVENUE" | "SREC" | "GAS" | "CARBON_RETIREMENT" | "APPRAISAL" | "ZONING_LETTER" | "LOAD_LETTER"
Payload: { dealId, docType, contentHash: sha256(file), uri, metadata }

## Waterfall signal (period close -> CMBSWaterfall)
{ "dealId": "...", "period": n, "paymentMinor": "uint256 USDC 6dp", "periodDays": 30,
  "utilityAmountMinor": "uint256 (PRIORITY-1: utility invoice, paid first, 3-arg distribute)",
  "dscrBps": "uint256 -> DSCRTrigger.update", "ltvBps": "uint256" }
Reconciliation: WaterfallAgent must match scripts/waterfall_model.py bit-identically or HALT.
