# Cloudflare Email Routing — Setup Guide
## unykorn.org + unykorn.ai → forwarded to your Gmail

> **Purpose:** Configure `kevan@unykorn.org`, `info@unykorn.org`, `kevan@unykorn.ai`, `info@unykorn.ai` (and any other addresses you want) so they all forward to `kevanbtc@gmail.com` for reliable delivery. Cloudflare Email Routing is free, handles MX + SPF + DKIM automatically, and takes ~10 minutes to set up per zone.
>
> **Why I couldn't do this for you directly:** I don't have your Cloudflare API token or dashboard access from this session. If you want me to script this via the Cloudflare API in a future run, hand me a token scoped to `Email Routing:Edit` and `Zone:DNS:Edit` for `unykorn.org` and `unykorn.ai`, and I'll write the API script. For now, here's the click-path.

---

## Part 1 — Enable Email Routing on `unykorn.org` (~5 min)

1. Log in to **https://dash.cloudflare.com** with the account that owns the `unykorn.org` zone.
2. Select the **`unykorn.org`** zone from the home dashboard.
3. In the left sidebar, click **Email** → **Email Routing**.
4. Click **Get started** (or **Enable Email Routing** if the button reads that).
5. Cloudflare will show a screen titled *"Get started with Email Routing"*. Click **Add records and enable**.
   - This automatically adds three `MX` records pointing to `route1.mx.cloudflare.net`, `route2.mx.cloudflare.net`, `route3.mx.cloudflare.net` (all priority 40).
   - It also adds an `SPF` (`TXT`) record: `v=spf1 include:_spf.mx.cloudflare.net ~all`
   - DKIM is handled automatically by Cloudflare — no manual DNS entry.
6. **Warning that will appear:** Cloudflare will ask if you have any existing MX records for this zone. If you do (e.g., Google Workspace, Zoho), Email Routing will REPLACE them. If `unykorn.org` currently receives email through another provider you want to keep, stop here and ask. If not, continue.
7. Confirm. Cloudflare provisions MX/SPF in ~30 seconds.

## Part 2 — Verify your destination Gmail (~2 min, one-time)

1. Still in **Email Routing**, click the **Destination addresses** tab.
2. Click **Add destination address**.
3. Enter `kevanbtc@gmail.com`.
4. Cloudflare sends a verification email to that address. Open the email in Gmail (subject: *"Verify your email address on Cloudflare"*), click the verification link.
5. Return to the Cloudflare dashboard — the destination address should now show as **Verified**.

If you want a second destination (e.g., another Gmail or a partner's inbox), add and verify them the same way. You can route different senders/aliases to different destinations.

## Part 3 — Create your forwarding routes on `unykorn.org` (~3 min)

1. Click the **Routes** tab (or **Custom addresses** — Cloudflare renamed this recently; either is the same screen).
2. Click **Create address**.
3. Fill in:
   - **Custom address**: `kevan`  (the part before `@unykorn.org`)
   - **Action**: `Send to an email`
   - **Destination**: `kevanbtc@gmail.com` (or whichever you verified)
4. Click **Save**.
5. Repeat for `info` → `kevanbtc@gmail.com`.
6. Recommended additional addresses to add now (each adds negligible cost/complexity):
   - `hello` → `kevanbtc@gmail.com`
   - `contact` → `kevanbtc@gmail.com`
   - `press` → `kevanbtc@gmail.com`
   - `legal` → `kevanbtc@gmail.com`
   - `deals` → `kevanbtc@gmail.com`
   - `investors` → `kevanbtc@gmail.com`

Optional catch-all: on the **Routes** tab, toggle the **Catch-all** rule ON and set it to forward to `kevanbtc@gmail.com`. This means any typo — `keven@unykorn.org`, `kevin@unykorn.org`, `admin@unykorn.org` — still reaches you. Recommended.

## Part 4 — Repeat for `unykorn.ai` (~5 min)

Same steps 1-6 above, but select the `unykorn.ai` zone. Same destination (`kevanbtc@gmail.com`). Same set of custom addresses.

If you want the same aliases on both zones (`kevan@unykorn.org` AND `kevan@unykorn.ai` both go to your inbox), configure them on both zones separately — Cloudflare treats each zone independently.

## Part 5 — Test (~2 min)

From any external email account (personal Gmail, a friend, your phone), send a test message to:
- `kevan@unykorn.org`
- `info@unykorn.org`
- `kevan@unykorn.ai`
- `info@unykorn.ai`

Check `kevanbtc@gmail.com` — messages should arrive within 30 seconds. If they land in Spam, mark as Not Spam and Gmail will learn.

## Part 6 — Sending FROM these addresses (optional, 15 min)

Cloudflare Email Routing **only handles inbound**. If you want to reply from `kevan@unykorn.org` (not `kevanbtc@gmail.com`), you have two options:

**Option A — Gmail "Send As" (free, easiest):**
1. In Gmail, go to **Settings** → **Accounts and Import** → **Send mail as** → **Add another email address**.
2. Enter `kevan@unykorn.org`.
3. Gmail will ask for SMTP credentials. Since Cloudflare doesn't provide outbound SMTP, use a third-party SMTP relay. Simplest free option: **Resend** (up to 100/day free) or **Amazon SES** (62,000/mo free from EC2).
4. Configure the SMTP relay to authorize sending as `kevan@unykorn.org`. Both Resend and SES require adding a DKIM `TXT` record to the Cloudflare DNS for `unykorn.org` — the relay will give you the exact records.
5. Once configured, Gmail will let you compose from either address.

**Option B — Google Workspace (paid, cleanest):**
1. Buy a Google Workspace seat for `kevan@unykorn.org` (~$7/user/month).
2. This gives you real Gmail on the custom domain with full inbound + outbound.
3. **Important:** if you do this, you must DISABLE Cloudflare Email Routing for that zone (Workspace will use its own MX records). You can't run both.

For now, Option A + Cloudflare Email Routing is the recommended path — free, works fine, and you can upgrade to Workspace later if volume demands.

---

## Verify everything looks right

After you finish Part 1-5, run this from any terminal to sanity-check MX/SPF:

```bash
dig +short MX unykorn.org
# Should return: 40 route1.mx.cloudflare.net · 40 route2.mx.cloudflare.net · 40 route3.mx.cloudflare.net

dig +short TXT unykorn.org | grep spf
# Should return: "v=spf1 include:_spf.mx.cloudflare.net ~all"

dig +short MX unykorn.ai
# Same three routeX.mx.cloudflare.net records

dig +short TXT unykorn.ai | grep spf
# Same SPF record
```

If any of those come back empty or wrong, DNS may not have propagated yet — wait 5 minutes and retry.

---

## Rollback (if anything goes sideways)

1. In Cloudflare dashboard → the affected zone → **Email** → **Email Routing** → **Overview**.
2. Click **Disable Email Routing** at the bottom.
3. This removes the MX / SPF records Cloudflare added. If you have previous MX records (from Google Workspace, Zoho, etc.) that you need to restore, add them back manually in **DNS** → **Records**.

---

## What was updated in the site to match this change

- `docs/index.html` — footer contact now `kevan@unykorn.org`.
- `docs/pages/contact.html` — primary email is `kevan@unykorn.org`, secondary is `info@unykorn.org`. Note added that all `@unykorn.org` and `@unykorn.ai` addresses route through Cloudflare Email Routing to the operator inbox. Schema.org JSON-LD updated.
- `docs/pages/government-programs.html` — footer contact updated.
- `docs/humans.txt` — contact updated.

All references to `kevan@ldrcllc.com` have been removed from the public site.

---

## If you want me to script it

Give me a Cloudflare API token in a future session (scope: `Zone → DNS → Edit` + `Email Routing → Edit` for `unykorn.org` and `unykorn.ai`) and I'll write a `scripts/setup-email-routing.sh` that:
- Enables Email Routing on both zones,
- Adds `kevanbtc@gmail.com` as a destination (you still have to click the verification link in Gmail — that step is unavoidable by design),
- Creates all the routes (`kevan`, `info`, `hello`, `contact`, `press`, `legal`, `deals`, `investors`),
- Sets the catch-all,
- Verifies MX / SPF records propagated correctly.

That would run in ~30 seconds vs. the ~15-minute click-through. But I need the token from you — I can't touch your Cloudflare without one.
