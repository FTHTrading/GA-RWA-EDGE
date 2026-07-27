# 🟦 Contracts

**27 Solidity files. solc 0.8.36 · EVM Cancun · Foundry.**

## Build

```bash
forge build
forge test
```

Status: `Compiler run successful.` (planning-grade; not audited; not for mainnet value).

## Layout

```text
src/core/                Roles · ECDSALib · AttestationVerifier · ReserveProofAnchor
                         DealRegistry · CustodyAdapter · AMLTravelRuleGate
                         LDTimelock · ReentrancyGuard · FeeCollector
src/interfaces/          ICompliance (ERC-3643-aligned) · IERC20
src/compliance/          IdentityRegistry · ModularCompliance · LDSecurityToken (ERC-3643)
src/compliance/modules/  Rule144LockupModule · CountryRestrictModule · MaxHoldersModule
src/paths/cmbs/          TrancheToken · DSCRTrigger · CMBSWaterfall
src/vaults/              AsyncVault (ERC-7540 seed) · MultiAssetEntry (ERC-7575 seed)
src/esg/                 SRECModule · CarbonModule · GasAttestation
script/                  Deploy scripts (deterministic wiring order)
test/                    Foundry test suite
```

See [CONTRACT_MAP.md](./CONTRACT_MAP.md) for the full inventory + deploy DAG.

## Hard invariants

- 🟥 **Priority 1 in every waterfall = utility / PPA payment.** Never subordinate to senior debt.
- 🟥 **Unykorn LLC holds no investor value.** FeeCollector routes all fees to Unykorn treasury via pull-and-immediate-forward.
- 🟥 **Compliance is a hard gate.** ERC-3643 IdentityRegistry + AMLTravelRuleGate check every transfer.
- 🟥 **Integer minor units only.** All monetary values in cents / minor units — no decimal drift.
- 🟥 **Owner ≠ Agent.** Multisig owner, automation-key agents. Never collapse both.

## Production-readiness notes per new module

| Contract | Status | What's needed for production |
|---|---|---|
| `FeeCollector` | Ready for testnet | Adversarial-tx testing on treasury-rotation event ordering |
| `AsyncVault` | Seed only | Full ERC-7540 (share() view, ERC-165, per-request view helpers, compliance re-check in claim(), ERC-7887 + ERC-8161 wiring) |
| `MultiAssetEntry` | Seed only | ERC-7575 view functions on entry vaults, ERC-165, decimal normalization enforcement |
| `SRECModule` / `CarbonModule` | Ledger only | Companion ERC-3643 wrapper tokens (RECToken / CarbonToken) for secondary transfer |
| `GasAttestation` | Ready for testnet | Enforce `evidenceHash` presence check against ReserveProofAnchor read before production write |
