# Deployment Runbook

Testnet → mainnet deployment sequence for the GA-RWA-EDGE contract suite.

## Prerequisites (all must clear before mainnet)

- ⛔ Dual independent smart-contract security audits
- ⛔ Securities counsel Rule 144 opinion + offering documents (Reg D 506(c) / Reg S)
- ⛔ Off-chain legal SPV package for each `ReserveProofAnchor` reserve
- ⛔ BD registration (own) or BD-of-record engagement letter executed
- ⛔ BitGo Bank & Trust N.A. custody engagement live
- ⛔ CPA administrator retained for QOF 90% asset test + OBBBA reporting
- ⛔ Multisig owner deployed (Safe or equivalent, minimum 3-of-5)
- ⛔ Agent keys provisioned in BitGo / Fireblocks with velocity caps

## Deploy sequence

Deterministic wiring order — do not vary:

1. **Core primitives** (owner-only setup)
   - `Roles` (via constructor of first contract)
   - `ECDSALib` (library — no state, no owner)
   - `AttestationVerifier` (multi-attestor quorum config)

2. **Attestation layer**
   - `ReserveProofAnchor` (constructor takes `AttestationVerifier`)

3. **Compliance core**
   - `IdentityRegistry`
   - `ModularCompliance`
   - Attach modules: `Rule144LockupModule` · `CountryRestrictModule` · `MaxHoldersModule`

4. **Token layer**
   - `LDSecurityToken` (ERC-3643) — wire to `IdentityRegistry` + `ModularCompliance`
   - `CustodyAdapter` — configure BitGo integration parameters

5. **Registry + AML**
   - `DealRegistry`
   - `AMLTravelRuleGate`
   - `LDTimelock` (for privileged operations)

6. **Path: CMBS / edge DC**
   - `TrancheToken` (per tranche)
   - `DSCRTrigger` (configured for the SPE's coverage covenant)
   - `CMBSWaterfall` — **Priority 1 = utility / PPA payment (non-negotiable)**

7. **Fee routing**
   - `FeeCollector` (constructor takes Unykorn treasury address)
   - Enable fee kinds per operational policy

8. **Vaults (if issuing pool shares)**
   - `AsyncVault` (ERC-7540)
   - `MultiAssetEntry` (ERC-7575)

9. **ESG modules**
   - `SRECModule`
   - `CarbonModule`
   - `GasAttestation`

10. **Role grants**
    - Owner → 3-of-5 Safe multisig
    - Agents → automation keys with per-role velocity caps enforced at BitGo / Fireblocks

## Testnet workflow

```bash
# Sepolia
cd contracts
export SEPOLIA_RPC=https://...
export DEPLOYER_KEY=0x...     # NEVER USE IN PROD; use hardware signer

forge script script/DeployMHelen.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY
```

**Post-deploy verification:**

- Every contract has correct owner (Safe address, not deployer EOA)
- Every AGENT role granted only to expected keys
- `CMBSWaterfall` priority buckets configured with utility payment as bucket 0
- `FeeCollector` treasury = Unykorn treasury Safe (not deployer)
- `IdentityRegistry` has no test identities registered
- `ReserveProofAnchor` has no test anchors present

## Mainnet workflow

Only after every prerequisite is cleared. Sequence identical to testnet with:

- `--rpc-url` set to mainnet RPC (Alchemy / Infura / self-hosted)
- Deployer = hardware signer (Ledger / Frame) with explicit approval per tx
- Owner transferred to Safe multisig within same tx block as deployment (transactional atomicity)
- Broadcast batched — do not sign then wait; single-session broadcast to prevent replay window
- Every artifact archived: `broadcast/*.json`, ABI outputs, contract addresses to `deployments/<network>/`

## Rollback / emergency response

- `LDTimelock` provides delay window for privileged ops — attackers can be countered before execution
- Owner-only pause functions on critical contracts (implementation-specific)
- BitGo custody enforces final velocity caps regardless of on-chain state
- Incident response plan: contact securities counsel + BitGo + BD counterparty within 1 hour of detection

## Not audited · not for mainnet value until every prerequisite clears
