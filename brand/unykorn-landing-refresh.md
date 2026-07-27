# Unykorn.ai / Unykorn.org — Landing Refresh Draft
## What's on the sites now vs. what it should be

> **How to use this doc:** This is a rewrite brief for whoever operates `unykorn.ai` and `unykorn.org`. I don't have direct access to those repositories from this session, so this is a paste-ready copy deck plus explicit design/asset direction. Hand it to whoever ships the landing page — or if you tell me where the repos live (Cloudflare Pages? separate GitHub? Wrangler?), I can push directly next round.

---

## 1. What I saw on the sites now (fetched today)

**unykorn.ai** currently leads with:
- Nav: `Platform · Trust · Security · Entities · Institutional · Portal`
- Hero: *"Non-custodial sovereign banking infrastructure."*
- Subhead: *"Unykorn is institutional-grade infrastructure for non-custodial banking, real-world-asset tokenization, and multi-rail settlement. Compliance is enforced as a gate before value moves — not filed as a report after."*
- 3 value props: Non-custodial by construction · Compliance as a gate · Multi-rail settlement
- 6 platform capabilities: Custody · Tokenization · Structured Credit · Construction Lending · Clean Energy · Settlement Rails
- Evidence-first block: Legal entities · Trust Center · Security
- Footer: LEI 2549008J7LUHSQ73SI26 · D-U-N-S 145059107 · Alpharetta, GA

**unykorn.org** is a stub — only headline visible ("UnyKorn Distribution OS — Tokenization Without Limits"). Needs to be built out.

## 2. Honest read on the current unykorn.ai copy

**What's working:**
- "Compliance as a gate, not a report" is a legitimately strong line. Keep that.
- The six-capability grid is the right structural pattern.
- The evidence-first block (LEI/DUNS/EIN) is the kind of trust signal institutional counterparties expect.
- "Multi-rail settlement, one money type" is distinctive.

**What's off:**
- "Non-custodial sovereign banking infrastructure" is too broad. It reads like every other DeFi-flavored infra pitch — Coinbase, Fireblocks, BitGo, Anchorage, and eight custody startups all use variations. Nothing about it says *what you actually do*.
- "Banking" is a legally loaded word that invites regulator scrutiny you don't want. Unykorn isn't a bank and shouldn't imply it is. Swap to "financial infrastructure" or "settlement infrastructure" — same meaning, no bank-charter implication.
- No mention of the two verticals that are actually shipping: **RWA edge data centers** and **AI compute infrastructure financing**. That's the wedge; it should be the hero.
- No imagery. Just text. Institutional buyers spend 3 seconds deciding whether to keep reading. A visual anchor changes that.
- Alpharetta, GA is in the footer but nowhere in the hero — you're leaving Southeast/Atlanta geo SEO on the floor.

## 3. Recommended refresh — copy deck (paste-ready)

### Navigation (unchanged structure, tightened labels)
```
Unykorn    Platform · Edge DC · Trust · Entities · Contact    [Data Room]
```
The addition of `Edge DC` to nav is deliberate — makes the vertical visible before anyone reads a word of body copy.

### Hero — new (three options, pick one)

**Option A (my recommendation — RWA + edge DC forward, distinctive):**
```
Eyebrow:  RWA · EDGE DATA CENTERS · SETTLEMENT INFRASTRUCTURE
Headline: We put real assets on-chain — with the compliance built in, not bolted on.
Subhead:  Unykorn is the institutional settlement layer for tokenized real-world assets:
          Georgia edge data centers, AI compute infrastructure, PPA-anchored energy,
          and permissioned securities. Every value movement clears a compliance gate
          before it happens — not after.
CTAs:     Enter the data room  ·  Explore the platform  ·  Trust & entities
```

**Option B (more edge, less traditional):**
```
Eyebrow:  RWA · EDGE COMPUTE · SETTLEMENT
Headline: On-chain assets should be as boring as bank rails —
          and as fast as the internet.
Subhead:  Unykorn makes tokenized real-world assets — edge data centers, AI compute,
          energy, and permissioned securities — actually settle. Compliance is a gate
          at the wire, not a PDF you file next quarter.
CTAs:     Enter the data room  ·  See the stack  ·  Verify us
```

**Option C (very direct, plainspoken — no jargon):**
```
Eyebrow:  ATLANTA · ALPHARETTA · GEORGIA
Headline: The rails for tokenizing edge data centers, AI compute, and energy.
          Built in Georgia. Compliance-gated at the wire.
Subhead:  We're what an institutional buyer expects an RWA operator to look like —
          separated entities, delegated custody, ERC-3643 permissioned tokens,
          on-chain attestation instead of trust-me. Six live capabilities.
          One LEI. One shared identity spine.
CTAs:     Data room  ·  Platform  ·  Entities
```

My vote is Option A. Cleaner, less try-hard, still distinctive. Option B has the "edgy" quality you asked for but risks reading as clever-clever. Option C is safest but leaves distinctiveness on the floor.

### Three value props (rewritten, RWA + edge DC anchored)

```
1. RWA that actually clears
   ERC-3643 permissioned securities with identity-gated transfers.
   Tokens can't move to a wallet the issuer hasn't approved. Same rules
   securities counsel writes into a subscription document — enforced by
   the token itself.

2. Compliance at the wire, not the audit
   One AML / KYC / Travel-Rule check clears every transfer.
   The gate happens before the value moves. When the wire clears, it
   already satisfies the rule. There is no reconciliation.

3. Edge data centers, energy, and compute — on rails you can audit
   Georgia edge sites, AI compute infrastructure, PPA-anchored assets,
   and hospitality — all in the same architecture. Site SPEs isolate
   risk. The rails carry the tokens. Investors see a live attestation
   feed, not a marketing dashboard.
```

### Platform grid — 6 capabilities (edit-in-place tweaks)

Keep the structure. Tighten each one-liner:

| Capability | Current | Recommended |
|---|---|---|
| Custody | *"Non-custodial vaults, qualified-custody delegation, tenant-held backup keys."* | *"Delegated qualified custody. You hold the backup key. We never move alone."* |
| Tokenization | *"ERC-3643 (T-REX) permissioned securities with identity-gated transfers."* | *"ERC-3643 permissioned securities. Identity-gated. What a subscription document says — enforced by the token."* |
| Structured credit | *"CMBS tranching with a deterministic waterfall, DSCR triggers, land bonds."* | *"Deterministic CMBS waterfalls, DSCR triggers, land bonds. Auditable to the cent, quarter by quarter."* |
| Construction lending | *"Oracle-gated milestone draws with atomic mechanic's-lien waivers."* | *"Milestone draws that release on a signed inspection oracle — with the lien waiver produced atomically."* |
| Clean energy | *"SREC minting from revenue-grade telemetry; ITC tax-equity flips."* | *"SRECs minted from revenue-grade telemetry. Storage §48E ITC through 2033. Tax-equity flip modeling built in."* |
| Settlement rails | *"XRPL, native Rust L1, EVM, and fiat on one integer money type."* | *"XRPL, a native Rust L1, EVM, and fiat rails via licensed partners. One integer money type across all of them."* |

### NEW capability tile — add "Edge Data Centers" as the 7th (or promote to first)

Currently there is no explicit Edge DC tile. Add it:

```
Edge data centers  (put this FIRST in the grid)
Site SPEs holding PPA-anchored compute infrastructure across Georgia.
Tokenized senior notes wrap the operating cash flow. Non-recourse GPU
credit stacks on top. QROF equity closes the capital stack.
[Read →]
```

### Evidence-first block (keep, expand)

```
Legal entities → LEI 2549008J7LUHSQ73SI26 · D-U-N-S 145059107 ·
                 EIN 42-3536633 · ISO MIC UBEC · Alpharetta, GA
Trust center  → Custody attestation, compliance-gate model,
                 implemented standards
Security      → Pre-deploy audit posture, key-management separation,
                 responsible-disclosure
```

Add a *fourth* pillar: **Verifiable public metrics** — link to a public metrics feed showing on-chain figures (contract addresses, cumulative volume, attestation counts). If you don't have this yet, put a "Coming Q4 2026" placeholder — it signals you're building it, which is a trust signal in itself.

### Footer (minor tweaks)

Current:
```
© 2026 UnyKorn LLC. LEI 2549008J7LUHSQ73SI26 · D-U-N-S 145059107 · Alpharetta, GA
Platform: Custody · Tokenization · Structured Credit · Construction Lending · Clean Energy · Settlement Rails
Trust: Compliance Center · Security · Legal Entities
Access: Operations Portal · Asset Registry · Institutional Data Room · Contact
```

Recommended:
```
© 2026 UnyKorn LLC · LEI 2549008J7LUHSQ73SI26 · D-U-N-S 145059107 · EIN 42-3536633 · Alpharetta, GA
Platform:  Edge DC · Custody · Tokenization · Structured Credit · Construction · Clean Energy · Settlement
Trust:     Compliance Center · Security · Legal Entities · Metrics Feed
Access:    Data Room · Contact (kevan@unykorn.org · info@unykorn.org)
Sister:    ga-rwa.unykorn.ai · xrplloans.unykorn.org · tax.unykorn.org
```

Drop "Operations Portal" and "Asset Registry" from public footer — those are the private surfaces you flagged today. Add the sister-property row cross-linking to the GA-RWA-EDGE site (helps SEO domain authority for both).

## 4. Design direction (not just copy)

### Logos

I built these SVGs for the GA-RWA-EDGE site — they're the same brand family and will work here without modification:

```
docs/pages/assets/logo.svg       -- square mark, 200x200
docs/pages/assets/logo-wide.svg  -- horizontal lockup with wordmark + tagline
docs/favicon.svg                 -- 64x64 favicon
```

Grab those from the GA-RWA-EDGE repo and drop them into the unykorn.ai / .org assets folder. If you want distinct branding for each domain, we can iterate — but a single mark across the constellation is stronger for institutional recognition.

### Hero imagery

Currently there is none. Add one of these three:

**Option 1 — Architecture illustration (already built).** Use `docs/pages/assets/hero-edge-dc.svg` from GA-RWA-EDGE. Four horizontal layers: physical pods → PPA layer → on-chain layer → capital layer. Works as-is for the Unykorn hero because the same architecture applies across all six capabilities.

**Option 2 — Live metrics tile.** Small dashboard-style widget in the hero right column showing live-on-chain figures: contract addresses, cumulative attestation count, TVL. Not vanity metrics — the boring ones institutional buyers care about. Loads from a public metrics endpoint.

**Option 3 — Photograph of a Georgia edge data center site.** If you can get a legitimate photo of Barak/Brock or another site (with owner consent, no addresses or serial numbers visible), that grounds the abstract copy in a real physical asset. Highest impact but requires the photo asset — probably a 2-week timeline to actually acquire.

My recommendation: ship Option 1 now, add Option 2 in the next iteration, plan for Option 3 later.

### Color / type discipline

Current site reads clean and institutional. Keep that. Suggested tightening:

- **Palette:** obsidian (#0b0d10) + copper (#c8862e) + silver (#e5e7eb). Reserve emerald green (#4ade80) for "verified / stable" status pills only. This matches GA-RWA-EDGE and gives the constellation visual coherence.
- **Type:** Georgia serif for headlines, system-sans for body. Same as GA-RWA-EDGE. The serif signals institutional / permanent / thoughtful — the exact tone Unykorn should hit.
- **No hero video.** No parallax scroll. No auto-playing ambient music. Institutional buyers close tabs that autoplay.

## 5. Rewrites for common pages you'll likely need to touch

### `/entities` page (legal entities)

```
Headline:  We are who we say we are — verifiable in three registries.
Subhead:   Every Unykorn statement about jurisdiction, ownership, or authority
           traces to a public registry entry. If a counterparty asks "who
           are you really," this page is the answer.

Entity: UnyKorn LLC
Wyoming LLC · Filed July 1, 2026
EIN: 42-3536633
LEI: 2549008J7LUHSQ73SI26  (GLEIF-verified)
D-U-N-S: 145059107
ISO MIC: UBEC
Registered agent: [—]
[Link: GLEIF verification]  [Link: SAM.gov entity]

Entity: UNYKORN 7777 INC.
Delaware corporation
[EIN: —]
Role: master parent; holds equity, IP, BitGo Enterprise account.

Entity: LD Capital LLC (The Loan Depot Lending Co., Inc.)
Delaware entity
Role: issuer of record for Reg D 506(c) offerings; QROF administrator.

Entity: FTH Trading LLC
US LLC
Role: markets ops; secondary book; LDX brand; BD track.
```

### `/trust` page (trust center)

```
Headline:  Trust is not a policy page. It's a set of things you can verify.

Custody:
- Qualified custody delegated to [BitGo Bank & Trust N.A. / Anchorage].
- Multi-signature vaults. Unykorn cannot move funds alone under any condition.
- Tenant-held backup keys. Continuity of access if Unykorn ceases operation.
- Custody attestation: [link to signed monthly attestation from custodian]

Compliance:
- Identity registry (ERC-3643 T-REX standard) on-chain.
- Every wallet passes Persona or Parallel Markets AML/KYC before any token
  transfer. Enforcement at the token boundary — not a post-transfer audit.
- FATF Travel Rule payload attached to every value movement above threshold.
- Every attestation event has an on-chain receipt: [link to attestation feed]

Standards implemented:
- ERC-3643 (T-REX permissioned security tokens)
- ERC-7540 (async vaults for RWA)
- ERC-7575 (multi-asset entries)
- FATF Travel Rule
- FinCEN MSB registration parameters
- OCC-chartered custody delegation

Security posture:
- Pre-deploy audit: dual-firm independent Solidity audit before any mainnet
  deploy of contracts that touch value.
- Key management: hardware-security-module + geographic key separation.
- Responsible disclosure: security@unykorn.org · PGP key [link]
```

### `/edge-dc` NEW page

This is the vertical-forward page that ties Unykorn's platform to the real vertical thesis. Fetches from GA-RWA-EDGE:

```
Headline:  Edge data centers, tokenized.
Subhead:   Bankruptcy-remote Site SPEs. PPA-anchored compute. ERC-3643 senior
           notes. USD.AI-class non-recourse GPU credit. QROF equity closes
           the stack. This is what an institutional RWA compute play looks
           like in 2026.

[Embed / link to key sections of ga-rwa.unykorn.ai]
- Location strategy: Metro Atlanta AI compute · exurban ring OZ sites ·
  North Georgia hospitality corridor.
- Funding stack: sponsor equity + QROF cap-gains + USDA B&I + GPU credit
  (USD.AI / Trad.Fi & W3 / Framework AI Infra Fund) + equipment vendor.
- Government stack: OZ 2.0 rural 30% step-up · Storage §48E ITC through
  2033 · Georgia Data Center Sales Tax Exemption · Georgia Power carve-out.
- Live deal: Barak/Brock candidate site (Phase 0 diligence pending)

CTAs: See the GA-RWA-EDGE full site  ·  Data room  ·  Contact
```

## 6. What to hand to whoever ships this

**If you use Cloudflare Pages / Workers:**
1. This document + the four SVG assets from GA-RWA-EDGE `docs/pages/assets/`.
2. The commit hash of the current unykorn.ai deploy so we can branch from it cleanly.
3. Have them push a preview URL first (a Cloudflare Pages preview), so you can approve visually before it goes live.

**If you want me to ship it directly:**
Tell me:
- The Git repo URL for the unykorn.ai deploy
- The Cloudflare Pages / Workers project name
- Push access (SSH deploy key or GitHub App)

I'll push the refresh, roll it out to a preview, share the preview URL, and merge to production only on your APPROVE.

## 7. Timeline estimate

- **Copy-only refresh** (paste into existing template): 30 minutes of ops work once you have this doc.
- **Full refresh with new hero illustration + updated entities/trust pages**: half a day.
- **Adding the `/edge-dc` page + cross-linking to GA-RWA-EDGE**: half a day.
- **Live metrics feed** (Option 2 hero imagery): 2-4 days depending on what's already exposed via a public endpoint.

Total for a clean, RWA + edge DC forward refresh: **one day of ops work** if the repo is accessible; **one week end-to-end** if it includes acquiring photo assets or building a metrics endpoint.
