Date: 2026-08-21
Model: Ox Alpha (`stealth/ox-alpha`) draft + Grok 4.5 verification
Scope: design, security, function/correctness, efficiency
Method: Ox saw a truncated tree snapshot and often dumped planning instead of a report. Findings below are **only those Grok confirmed against the working tree**. Invented files and unverified “add tests” notes were dropped.

# Audit: noshi

## Snapshot
Rails 8 bilingual noshi generator. SQLite, Stripe subscriptions, Google OAuth, Kamal → Hetzner, Cloudflare. `force_ssl` already true. Production log level already `info`.

## Design
- Billing lives in `BillingController`: Checkout + Customer Portal + webhook. CSRF skipped only on `webhook`.

## Security
- **High** — `verified_event` accepted **unsigned** Stripe payloads whenever `STRIPE_WEBHOOK_SECRET` was unset, including production. Tests relied on that convenience path (no secret in test). This PR allows unsigned events only in `Rails.env.local?` (development/test) and rejects them otherwise.
- Stripe Checkout/portal flows look standard.

## Function
- Existing webhook tests still pass in test env. New test stubs `Rails.env` as production and asserts 400 when the secret is missing.

## Suggested follow-ups
1. Rails 8 `rate_limit` on `sessions#create` and `api/v1` — Effort S
2. Sync README Ruby/Rails versions (Dockerfile is 4.0.6) — Effort S
