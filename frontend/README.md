# 🟪 Frontend Portals

Scaffolding for admin + investor + sponsor portals. Next.js structure planned.

## Planned surfaces

### Admin portal (internal FTH Trading / LD Capital)

- Deal registration (`DealRegistry.registerDeal`) and status transitions
- SPE lifecycle management (creation → funding → servicing → matured / closed)
- Waterfall configuration (priority buckets, coverage triggers)
- Attestation monitoring (ReserveProofAnchor entries with search + filter)
- FeeCollector invoice generation and collection
- Emergency pause / role rotation

### Investor portal (accredited)

- Onboarding via Persona / Parallel Markets → `IdentityRegistry` on-chain claim
- Subscription flows (Reg D 506(c) verified accredited + Reg S non-US)
- Position dashboard (share balances, pending requests via `AsyncVault`, waterfall claims)
- Secondary transfer request UI (respects `ModularCompliance` rules)
- Tax reporting exports (QROF K-1 aids, holding-period tracking)

### Sponsor portal (Barak-type asset originator)

- PPA / site / KYC upload → feeds `DealOnboardingAgent`
- Contribution agreement drafting workflow
- Sponsor promote / carry dashboard

## Status

Not implemented. Ships with a Next.js scaffold once contracts are audited and deployed to testnet.

## Non-negotiable rules

- 🟥 Never render investor balances or waterfall math from off-chain state as authoritative. Always read from chain.
- 🟥 Every UI transfer flow must re-check the `IdentityRegistry` claim before signing.
- 🟥 No wallet key material touches the frontend server. Client-side signing only (WalletConnect / EIP-6963).
