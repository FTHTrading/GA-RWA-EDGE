# Scripts

Deployment, migration, and operational scripts.

## Contents

```text
scripts/                    Root operational scripts (bash / PowerShell)
../contracts/script/        Foundry deploy scripts (`.s.sol`)
```

## Foundry deploy scripts

Live at `contracts/script/`. Deterministic wiring order per the deploy DAG in `contracts/CONTRACT_MAP.md`.

Testnet deploy:

```bash
cd contracts
forge script script/DeployMHelen.s.sol --rpc-url $SEPOLIA_RPC --broadcast --verify
```

Deploy sequence:

1. Core: `Roles` (owner-only setup) → `ECDSALib` (library, no state) → `AttestationVerifier`
2. `ReserveProofAnchor` (constructor takes AttestationVerifier)
3. `IdentityRegistry` → `ModularCompliance` → attach modules (Rule144, CountryRestrict, MaxHolders)
4. `LDSecurityToken` (ERC-3643) → wire to IdentityRegistry + ModularCompliance
5. `DealRegistry` → `CustodyAdapter` → `AMLTravelRuleGate`
6. Path-specific: `TrancheToken` → `DSCRTrigger` → `CMBSWaterfall` (Priority 1 = utility payment)
7. `FeeCollector` (constructor takes Unykorn treasury address)
8. Vaults: `AsyncVault` → `MultiAssetEntry`
9. ESG: `SRECModule` → `CarbonModule` → `GasAttestation`
10. Grant AGENT role to automation keys (BitGo / Fireblocks) with velocity caps enforced upstream

## Pre-mainnet checklist

- ⛔ Dual independent audits complete
- ⛔ Securities counsel Rule 144 opinion on file
- ⛔ Legal SPV package for each `ReserveProofAnchor` reserve
- ⛔ BD-of-record engagement letter executed (or own BD approved by FINRA)
- ⛔ BitGo Bank & Trust N.A. custody engagement live
- ⛔ CPA administrator retained for QOF 90% asset test
- ⛔ Multisig owner deployed (Safe / equivalent, m-of-n = 3-of-5 minimum)

Never mainnet-deploy without every checkbox cleared.
