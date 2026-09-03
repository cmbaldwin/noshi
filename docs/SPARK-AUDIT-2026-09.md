# Spark 1.3 audit — noshi (2026-09-03)

Scope: Rails 8 noshi generator (SQLite, Google OAuth, Stripe, community
backgrounds, public JSON API). Built on `origin/main`; did not duplicate the
open Escalante-registry or markdown_for_agents PRs, nor the Aug 2026 Ox
Alpha security PRs (webhook signing, force_ssl).

## The 10 findings (severity · effort)

1. `SessionsController` skipped CSRF verification for **all** actions,
   including logout (DELETE) — session-riding logout CSRF.
   High · S
2. N+1: API `backgrounds`/`designs` and the admin gallery load
   `background.user` once per row via `background_json` / the view.
   Medium · S
3. `SavedNoshisController#attach_rendered_image` accepted an unbounded
   base64 data URL — memory/disk exhaustion from any paid account.
   Medium · S
4. API claims to be CORS-open, but no route answers `OPTIONS` — browser
   preflights 404 without CORS headers.
   Medium · S
5. `require_admin` told signed-in non-admins "please sign in" — wrong,
   misleading error for already-authenticated users.
   Low · S
6. `Subscription.upsert_from_stripe` uses `Time.at` (system zone) instead
   of `Time.zone.at` (Tokyo). No observable effect today — ActiveRecord
   stores the same UTC instant either way.
   Low · S
7. API `site_base_url` falls back to `request.base_url`, trusting the
   `Host` header for absolute editor/asset URLs.
   Medium · S
8. `NoshisController#new_noshi_params` ends in `.permit!` instead of an
   explicit permit list.
   Low · S
9. No rate limiting on the OAuth callback, Stripe webhook, or `rate`
   endpoint (Rails 8 has built-in `rate_limit`). Test env uses
   `:null_store`, so limits can't be verified here without extra setup.
   Medium · M
10. README still lists old Ruby/Rails versions (Dockerfile is 4.0.6).
    Docs-only.
    Low · S

## The 5 picked (all in this PR, each with a fail-before/pass-after test)

- **#1** — CSRF exemption scoped to `only: :create`. Real session-integrity
  hole, one-line fix, no behavior change for the Google callback.
- **#2** — `.includes(:user)` on the three listings that render the
  uploader. One-query fix, guarded by a query-count regression test.
- **#3** — 5 MB cap on rendered-image uploads (pre-decode size gate plus
  post-decode check). Paid-tier settings still save when the image is
  dropped; matches the method's existing silent-no-op style.
- **#4** — `OPTIONS /api/v1/*` → 204 with the CORS headers the app
  already intended. One route + three-line action.
- **#5** — new `auth.admin_required` message (ja/en) for signed-in
  non-admins; guests still get the sign-in prompt.

## Skipped and why

- **#6** — cosmetic only (same stored instant); not worth the diff.
- **#7** — changes URL generation per environment; needs proxy/Host
  behavior verified against staging, riskier than it looks.
- **#8** — behavior-equivalent hardening (params are already sliced to
  three keys); low value, skip.
- **#9** — can't verify under `:null_store` in this session; flagged for a
  follow-up with a real cache store in test.
- **#10** — docs-only; out of scope per the brief.

## Verification

Targeted tests only (per the brief — no full suite, no docker/kamal):

- `test/controllers/sessions_controller_test.rb` (new CSRF test)
- `test/controllers/api/v1/api_test.rb` (N+1 + preflight tests)
- `test/controllers/saved_noshis_controller_test.rb` (upload-cap tests)
- `test/controllers/admin/backgrounds_controller_test.rb` (admin-message tests)

Note: several pre-existing HTML-rendering tests error in this worktree
with `The asset 'tailwind.css' was not found in the load path` (assets
were never built here). Confirmed identical failures on the pristine
tree — unrelated to this PR.

## Diff stats

5 `fix:` commits, ~120 added lines total across controllers, routes,
locales, and tests. No migrations, no dependency changes, no secrets,
no deploy/registry config touched.
