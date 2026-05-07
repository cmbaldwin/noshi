# Noshi — Agent Context

> Last updated: 2026-05-07. Reference alongside README.md.

## What this app is

**Noshi.moab.jp** is a bilingual (Japanese/English) web app for generating *noshi* — the decorative folded paper bands traditionally attached to Japanese gift envelopes (*noshigami*, *熨斗紙*). The user fills in a gift type (*omotegaki*, e.g. 御祝), recipient names, and a visual style, then downloads a JPEG to print and attach.

**Key constraint:** this is a zero-persistence app. There is no database, no user accounts, no background jobs. Every request is stateless.

---

## Stack

| Concern | Choice |
|---|---|
| Language | Ruby 4.0.0 (`.ruby-version`) |
| Framework | Rails 8.0 |
| Frontend | Importmap + Stimulus + Turbo + Tailwind v2 (no Node/Webpack) |
| Assets | Propshaft (not Sprockets) |
| Server | Puma + Thruster (static asset serving/compression in prod) |
| Deployment | Kamal 2, Docker, AWS ECR (`moab/noshi`) |
| Hosting | Shared moab server (`5.223.51.74`), proxied by kamal-proxy |
| Domain | `noshi.moab.jp`, Cloudflare proxied, CF origin cert for TLS |
| CI/CD | None — `kamal deploy` from local machine |

---

## Rails configuration (minimal/stripped)

`config/application.rb` loads only what's needed — **no ActiveRecord, no ActiveStorage, no ActionMailer, no ActionCable**:

```ruby
require "action_controller/railtie"
require "action_view/railtie"
require "active_model/railtie"
require "rails/test_unit/railtie"
```

No `config/database.yml`, no `db/` directory, no migrations.

`SECRET_KEY_BASE` is the only required runtime secret (cookie/CSRF signing). Set in `.kamal/secrets`, injected as an env var.

No `config/credentials.yml.enc` — that was intentionally dropped.

---

## Model

`app/models/noshi.rb` — a plain Ruby object with `ActiveModel::Model`:

```ruby
class Noshi
  include ActiveModel::Model
  attr_accessor :ntype, :omotegaki, :names, :paper_size,
                :font_size, :omotegaki_size,
                :omotegaki_margin_top, :names_margin_top, :names_margin_bottom
end
```

Never persisted. All rendering is client-side.

---

## Routes

```
GET  /           → noshis#index   (main generator page)
GET  /noshis/new → noshis#new     (with optional params: /ntype/:names/:omotegaki)
POST /noshis     → noshis#create  (returns 204, no-op — form is client-side only)
GET  /about      → noshis#about
GET  /up         → rails/health#show
```

All routes are scoped under `(/:locale)` supporting `ja` (default) and `en`.

---

## Frontend architecture

The entire noshi preview is rendered in the browser via **`app/javascript/controllers/noshi_controller.js`** (Stimulus). Key libraries loaded via importmap:

- `html-to-image` — converts the DOM preview to a downloadable JPEG
- `@hotwired/turbo` and `@hotwired/stimulus`

The `noshi_preview.js` handles live canvas rendering as the user types. The form at `app/views/noshis/_form.html.erb` drives all input.

Noshi background images are in `app/assets/images/noshi/` (full-size) and `app/assets/images/noshi/thumbs/` (thumbnails).

---

## Localisation

`config/locales/ja.yml` and `en.yml`. Japanese is the default locale. All user-facing strings should use `t()` helpers.

---

## Deployment

### Infrastructure

- Runs as a container on the existing moab server alongside moab.jp
- `kamal-proxy` routes `noshi.moab.jp` → this service (no additional proxy config needed)
- Cloudflare origin cert covers `*.moab.jp` — shared with moab.jp

### Secrets (all gitignored, never commit)

| Secret | Source | Notes |
|---|---|---|
| `SECRET_KEY_BASE` | 1Password `MOAB/Production` vault | Any 128-char hex string |
| `CLOUDFLARE_SSL_CERT_PEM` | `config/ssl/cert.pem` (local file) | CF origin cert, valid until 2040 |
| `CLOUDFLARE_SSL_KEY_PEM` | `config/ssl/key.pem` (local file) | Paired private key |
| `AWS_ECR_PASSWORD` | `aws ecr get-login-password` | Auto-fetched, 12h TTL |

Gitignored paths: `/.kamal/secrets`, `/config/ssl/*.pem`, `/config/master.key`

### Deploy command

```bash
kamal deploy
```

Run from `/Users/cody/Dev/noshi`. Requires:
- 1Password CLI authenticated (`op signin`)
- AWS CLI configured (`~/.aws/credentials`, profile `default`, region `ap-southeast-2`)
- `config/ssl/cert.pem` and `config/ssl/key.pem` present locally

### `config/deploy.yml` notes

- Server IP and ECR registry URL are hardcoded (not secrets — public infrastructure)
- SSL pems use ERB: `<%= ENV['CLOUDFLARE_SSL_CERT_PEM'] %>` — value comes from `.kamal/secrets`
- `SECRET_KEY_BASE` is in `env.secret` list — Kamal reads it directly from the secrets env

---

## Testing

```bash
bin/rails test
```

Tests in `test/controllers/noshis_controller_test.rb` and `test/models/noshi_test.rb`. No system tests (selenium/capybara removed). No fixtures that reference a database.

---

## What was removed (vs original Render-era app)

- ActiveRecord, ActiveStorage, ActionMailer, ActionCable, ActiveJob
- Devise (users, auth)
- Redis, Sidekiq
- PostgreSQL / SQLite
- Sprockets → replaced by Propshaft
- `config/credentials.yml.enc` → replaced by `SECRET_KEY_BASE` env var
- Render deployment files (`render.yaml`, `render-db.yaml`, `render-sidekiq.yaml`)
- `Procfile` / `Procfile_old` (Kamal manages the process)

Removed files are archived in `controllers_removed/`, `models_removed/`, `views_removed/`, `db_removed/` for reference only — they are not loaded by Rails.

---

## Common tasks

| Task | Command |
|---|---|
| Local dev server | `bin/dev` |
| Deploy to production | `kamal deploy` |
| Rails console on server | `kamal console` |
| Tail production logs | `kamal logs` |
| SSH to server | `kamal shell` |
| Run tests | `bin/rails test` |
| Add a new noshi type | Add to the noshi `ntype` list in `_form.html.erb` and handle in `noshi_controller.js` |
| Add a new locale string | Edit `config/locales/ja.yml` and `en.yml` |
