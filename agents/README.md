# 🟩 MCP Agentic Fleet

Multi-agent operational layer built on the Model Context Protocol (MCP). Agents collaborate, hand off tasks, and maintain shared per-deal state.

## Agent inventory

| Agent | Role | MCP servers used |
|---|---|---|
| `DealOnboardingAgent` | Ingest PPA + site + KYC packages, run diligence, propose SPE structure | `document-server` · `chain-server` |
| `AttestationAgent` | Watch for new documents, hash them, call `ReserveProofAnchor` | `document-server` · `oracle-server` · `chain-server` |
| `ComplianceAgent` | Monitor `IdentityRegistry`, AML gates, travel-rule events | `kyc-server` · `chain-server` |
| `WaterfallAgent` | Execute and monitor `CMBSWaterfall.distribute()` | `chain-server` |
| `CapitalStackAgent` | Model QROF step-up · ITC · tax-equity sizing · DSCR · LTV | Spreadsheet + model export |
| `InvestorReportingAgent` | Generate on-chain + off-chain reports | `document-server` · `email-server` |
| `RiskMonitoringAgent` | DSCR · PPA termination risk · rural qualification flags | `chain-server` · `oracle-server` |
| `GeorgiaEnergyAgent` | GA zoning · voluntary RECs · gas hybrid · rural QROF screening | `document-server` + `config/georgia/*.json` |

## MCP servers

```text
mcp-servers/chain-server/       Blockchain RPC + contract read/write
mcp-servers/bitgo-server/       BitGo institutional custody API
mcp-servers/kyc-server/         Persona / Parallel Markets integration
mcp-servers/document-server/    IPFS/Arweave + traditional document storage
mcp-servers/oracle-server/      Oracle price / NAV / attestation feeds
```

## Status

Scaffolding only. TypeScript implementations in `src/` are stubs — production requires:

- MCP protocol client / server wiring against the current MCP spec
- Persistent per-deal state store (Postgres or embedded SQLite)
- Retry / idempotency for on-chain writes
- Audit-log emission for every agent action

Non-negotiable: **agents never hold assets or capital**. They orchestrate; SPEs and BitGo hold value.
