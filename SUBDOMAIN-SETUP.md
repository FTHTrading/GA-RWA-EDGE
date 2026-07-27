# Subdomain Setup — ga-rwa.unykorn.ai
## From GitHub Pages → Custom Subdomain + SEO Bootstrap

> **Target:** `https://ga-rwa.unykorn.ai/`
> **Current:** `https://fthtrading.github.io/GA-RWA-EDGE/`
> **Repo:** `github.com/FTHTrading/GA-RWA-EDGE`

The default subdomain choice is `ga-rwa.unykorn.ai` (already committed as `docs/CNAME`). Alternatives if you prefer a different label:

- `atlanta.unykorn.ai` — geo-forward, best pure SEO for Atlanta queries
- `edge.unykorn.ai` — brand-forward
- `ldx.unykorn.ai` — matches the LDX brand system
- `capital.unykorn.ai/ga-rwa/` — subpath under existing capital portal (requires Cloudflare Pages/Workers routing, not just DNS)

If you want a different label, change the `docs/CNAME` file to that hostname and update the sitemap URLs (they encode the domain).

---

## 1. Cloudflare DNS setup (3 minutes)

Log into Cloudflare, select the `unykorn.ai` zone, and add:

| Type | Name | Content | Proxy status | TTL |
|---|---|---|---|---|
| CNAME | ga-rwa | fthtrading.github.io | **Proxied (orange cloud)** | Auto |

That's it. GitHub Pages will detect the `CNAME` file already committed to `docs/CNAME` on next push, and Cloudflare will serve.

Verify the CNAME propagated with:

```bash
dig ga-rwa.unykorn.ai
# or
nslookup ga-rwa.unykorn.ai
```

Should resolve to a Cloudflare edge IP within 60 seconds.

---

## 2. GitHub Pages: enable custom domain

Once DNS resolves, in the repo's Settings → Pages:

1. Custom domain: `ga-rwa.unykorn.ai` (should auto-populate from the `docs/CNAME` file).
2. Wait ~1-2 minutes for GitHub to verify.
3. Check "Enforce HTTPS" — should become available once cert is provisioned (usually <10 minutes).

If GitHub does not auto-provision HTTPS, force a re-check by toggling the custom domain off and on again in the Pages settings.

---

## 3. Cloudflare: SSL/TLS mode

In the `unykorn.ai` zone → SSL/TLS → Overview:

- Encryption mode: **Full** (not "Full (strict)" until GitHub's cert is provisioned; then upgrade).
- Once GitHub Pages issues its cert, upgrade to **Full (strict)**.

Under SSL/TLS → Edge Certificates:

- Always Use HTTPS: **On**
- Automatic HTTPS Rewrites: **On**
- Minimum TLS Version: **TLS 1.2** or higher

---

## 4. Google Search Console — the actual SEO ignition step

This is the step that most Atlanta search visibility depends on. GitHub Pages does not auto-submit to Google.

1. Go to https://search.google.com/search-console
2. Add property → Domain property → `unykorn.ai` (verifies the whole apex + all subdomains including ga-rwa)
3. Verify via Cloudflare DNS TXT record (Google will provide the exact string; add it as a TXT at the apex).
4. Once verified, add sitemap: `https://ga-rwa.unykorn.ai/sitemap.xml`
5. Request indexing for the top pages one-by-one:
   - `https://ga-rwa.unykorn.ai/`
   - `https://ga-rwa.unykorn.ai/pages/atlanta-market.html`
   - `https://ga-rwa.unykorn.ai/pages/locations.html`
   - `https://ga-rwa.unykorn.ai/pages/funding-sources.html`
   - `https://ga-rwa.unykorn.ai/pages/whitepaper.html`

Google's crawler will begin indexing over the following 24-72 hours. First-appearance-in-search typically 3-14 days after that.

---

## 5. Bing Webmaster Tools

Same steps at https://www.bing.com/webmasters. Bing typically indexes faster than Google (24-48 hours). Also feeds ChatGPT search and DuckDuckGo.

---

## 6. What was actually built for SEO in this commit

The site had almost no SEO before. This commit added:

### Foundation files
- `docs/CNAME` — sets `ga-rwa.unykorn.ai` as the target host.
- `docs/robots.txt` — allows crawl of the public pages, disallows `build-loop/` (internal), points crawlers to the sitemap.
- `docs/sitemap.xml` — all 13 public pages with priorities, `lastmod`, and `changefreq`.
- `docs/humans.txt` — trust signal + attribution.

### Structured data (JSON-LD)
- `docs/index.html` — full `Organization`, `FinancialService`, `WebSite`, and `FAQPage` schema with Atlanta / Georgia `areaServed`. Links to sister Unykorn properties for cross-domain SEO authority.
- `docs/pages/atlanta-market.html` — new dedicated Atlanta AI compute page with `Article` schema targeting Metro Atlanta, exurban ring counties (Douglas, Paulding, Bartow, Newton, Carroll, Cherokee, Forsyth, Henry, Rockdale), and Atlanta hyperscaler-adjacent keywords.
- `docs/pages/locations.html` — `ItemList` schema with three physical `Place` items (Barak rural GA, M Helen Helen GA, Atlanta pipeline), each with `PostalAddress` and `GeoCoordinates`.

### Meta tags on all 14 pages
- Geo meta (`geo.region`, `geo.placename`, `geo.position`, `ICBM`).
- Canonical URLs pointing to `ga-rwa.unykorn.ai`.
- Open Graph + Twitter Card tags on every page for rich sharing previews.
- Atlanta / Georgia keywords in `<title>` and `<meta name="description">` on every page.
- `<meta name="keywords">` on high-value pages (deprecated but harmless).

### Cross-domain authority
- Cross-links in `<head>` of index.html via `<link rel="alternate">` to `portal.unykorn.ai`, `capital.unykorn.ai/platform/`, `xrplloans.unykorn.org`.
- Same links appear as inbound-outbound trust signals within footer/body content.

---

## 7. Why you weren't showing up before

Three compounding reasons:

1. **`fthtrading.github.io` is a shared subdomain of `github.io`** — that domain has enormous Google authority as a whole but individual `*.github.io/<repo>/` paths inherit almost none of it. Custom subdomain on your own second-level domain (`unykorn.ai`) with existing sister properties builds *your* domain authority instead of GitHub's.

2. **Zero structured data** — Google's E-E-A-T (experience, expertise, authoritativeness, trust) signals rely heavily on schema.org markup. Without `Organization`, `FinancialService`, or `Place` schema, Google treats the pages as generic HTML with no entity resolution. The Atlanta / Georgia geo isn't findable because the pages weren't declaring geo.

3. **No sitemap submitted, no search-console verification** — GitHub Pages does not auto-notify Google. Even a well-optimized site takes 2-4 weeks to appear organically without a sitemap submission. Since the pages have only been live for days, they wouldn't have appeared anyway. The sitemap + Search Console submission accelerates this by 5-10x.

The Atlanta search visibility should start appearing within 5-14 days after:
- DNS is live (step 1-3 above),
- Sitemap submitted to Google Search Console (step 4),
- Bing sitemap submitted (step 5).

---

## 8. Ongoing SEO — what to add next

Not blocking for launch. Add over the next 2-4 weeks:

1. **Blog / insights section** — `docs/pages/insights/` — 4-6 posts on Atlanta AI infra, Georgia OZ, USD.AI GPU credit, Georgia Power large-load carve-out. Each post is a new indexable URL targeting a different long-tail keyword cluster.
2. **Google Business Profile** — if there's a physical Atlanta office address (even a virtual mailbox), claim a GBP listing. Google Business ranks separately from web SEO for "near me" queries.
3. **Backlink acquisition** — inbound links from unykorn.ai, xrplloans.unykorn.org, capital.unykorn.ai, and any partner sites (BitGo, Persona) that agree to a mention. Backlinks are still the single biggest ranking factor.
4. **Twitter / LinkedIn presence** — post the Atlanta market thesis; Google indexes social profiles as trust signals for entity resolution.
5. **PR pickup** — a single mention in Bisnow Atlanta, Data Center Frontier, or Atlanta Business Chronicle would 10x organic reach.

---

## 9. Rollback

If the subdomain deployment causes any issue, revert by:

1. Deleting the CNAME record at Cloudflare.
2. Removing custom domain in GitHub Pages Settings.
3. Deleting `docs/CNAME` file and pushing.

Site returns to `fthtrading.github.io/GA-RWA-EDGE/` within minutes.
