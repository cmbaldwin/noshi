# Noshi Kamal Deployment + Simplification Plan

> Drafted 2026-05-06 with Claude. Pick up here if the session was interrupted.

## Context

Noshi is a single-page client-side-JS noshi (Japanese decorative placard) generator. Currently:
- Rails 7.0.8 / Ruby 3.2.2
- Deployed on Render (free tier) with `render.yaml`, `render-db.yaml`, `render-sidekiq.yaml`
- **No DB persistence** — `Noshi` is a PORO with `ActiveModel::Model`; no migrations, no AR records
- Redis configured for ActionCable but ActionCable not actually used
- Sidekiq listed in commented-out gems and Procfile but not in Gemfile
- Importmap + Tailwind + Turbo + Stimulus + Sprockets

## Goal

1. Strip the app to absolute minimum frameworks (no AR, no AS, no AM, no AC).
2. Migrate to Rails 8 + Ruby 4.0.0 (matching `~/dev/moab` and `~/dev/oroshi` patterns).
3. Migrate Sprockets → Propshaft (Rails 8 default).
4. Deploy via Kamal to `noshi.moab.jp` on the existing moab server.

## Infra reuse (key insight)

The moab server is already running Kamal proxy and host-routes by `proxy.host:`. We piggyback:

| Concern | Reuse |
|---|---|
| Server | existing moab host (IP in `.kamal/secrets`) |
| Kamal proxy | already running, just adds noshi as another routed service |
| Registry | AWS ECR (account + region in `.kamal/secrets`), repo `moab/noshi` |
| 1Password vault | shared `MOAB/Production` vault (account ID in `.kamal/secrets`) |
| SSL | Cloudflare origin cert from 1Password (`CLOUDFLARE_SSL_CERT_PEM` / `CLOUDFLARE_SSL_KEY_PEM`) |
| DNS | `noshi.moab.jp` → moab host, Cloudflare proxied |

**Open question:** does the existing Cloudflare origin cert cover `*.moab.jp` or only the apex `moab.jp`? If apex-only, re-issue with `moab.jp, *.moab.jp` SANs in CF dashboard before deploying.

## Phase 1 — Strip the Rails app

### Upgrades

- `.ruby-version`: `3.2.2` → `4.0.0`
- `Gemfile`: `gem "rails", "~> 7"` → `gem "rails", "~> 8.0"`
- Sprockets → Propshaft
- Tailwind v3 → v4 (via `tailwindcss-rails` upgrade)

### Strip Rails frameworks

In `config/application.rb`, replace `require "rails/all"` with selective requires:

**Keep:**
- `action_controller/railtie`
- `action_view/railtie`

**Drop:**
- `active_record/railtie`
- `active_storage/engine`
- `action_mailer/railtie`
- `action_mailbox/engine`
- `action_text/engine`
- `action_cable/engine`
- `active_job/railtie`

### Gem removals

- `redis` (no ActionCable use)
- `sprockets-rails` (replaced by propshaft)
- Commented `# gem "pg"` and `# gem "sidekiq"` lines
- `selenium-webdriver`, `webdrivers`, `capybara` (if not actively used)

### File deletes

- `config/database.yml`
- `config/cable.yml`
- `config/storage.yml`
- `db/`
- `app/jobs/`
- `app/workers/` (NoshiWorker is commented Sidekiq scaffolding)
- `app/channels/` (if generated)
- `bin/render-build.sh`
- `Procfile`, `Procfile_old`
- `render.yaml`, `render-db.yaml`, `render-sidekiq.yaml`

## Phase 2 — Add Kamal scaffolding

### `Dockerfile`

Copy moab's pattern with subtractions:

- `ARG RUBY_VERSION=4.0.0`
- Multi-stage: `base` → `build` → final
- Final-stage system packages: `curl`, `libjemalloc2`, `libvips` — **drop `postgresql-client`**
- Build packages: `build-essential`, `git`, `libyaml-dev`, `pkg-config` — **drop `libpq-dev`**
- **Drop Node/Yarn install entirely** (importmap means no JS bundle step)
- Assets: `SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile` (tailwindcss-rails hooks into precompile)
- Non-root `rails` user UID/GID 1000, owns `/rails`, `log`, `tmp`, `public`
- `EXPOSE 80`
- `ENTRYPOINT ["/rails/bin/docker-entrypoint"]`
- `CMD ["./bin/thrust", "./bin/rails", "server"]`

### `bin/docker-entrypoint`

Pure exec passthrough — drop moab's `db:prepare` (no DB).

```bash
#!/bin/bash -e
exec "${@}"
```

### `config/deploy.yml`

```yaml
service: noshi
image: moab/noshi

ssh:
  user: root

servers:
  web:
    - <%= ENV['DEPLOY_SERVER_IP'] %>

proxy:
  ssl:
    certificate_pem: <%= ENV['CLOUDFLARE_SSL_CERT_PEM'] %>
    private_key_pem: <%= ENV['CLOUDFLARE_SSL_KEY_PEM'] %>
  host: noshi.moab.jp
  app_port: 80
  forward_headers: true
  healthcheck:
    path: /up
    interval: 10
    timeout: 30

registry:
  server: <%= ENV['ECR_REGISTRY'] %>
  username: AWS
  password:
    - AWS_ECR_PASSWORD

env:
  secret:
    - SECRET_KEY_BASE
    - CLOUDFLARE_SSL_CERT_PEM
    - CLOUDFLARE_SSL_KEY_PEM

builder:
  arch: amd64

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell:   app exec --interactive --reuse "bash"
  logs:    app logs -f
```

### `.kamal/secrets`

```bash
# Real values live in this gitignored file; placeholders shown here.
DEPLOY_SERVER_IP=<your-server-ip>
ECR_REGISTRY=<aws-account>.dkr.ecr.<region>.amazonaws.com
ONE_PW_ACCOUNT=<1password-account-id>

SECRETS=$(kamal secrets fetch --adapter 1password --account $ONE_PW_ACCOUNT --from "MOAB/Production" NOSHI_SECRET_KEY_BASE CLOUDFLARE_SSL_CERT_PEM CLOUDFLARE_SSL_KEY_PEM)
SECRET_KEY_BASE=$(kamal secrets extract NOSHI_SECRET_KEY_BASE ${SECRETS})
CLOUDFLARE_SSL_CERT_PEM=$(kamal secrets extract CLOUDFLARE_SSL_CERT_PEM ${SECRETS})
CLOUDFLARE_SSL_KEY_PEM=$(kamal secrets extract CLOUDFLARE_SSL_KEY_PEM ${SECRETS})
AWS_ECR_PASSWORD=$(aws ecr get-login-password --region <region> --profile default)
```

> Why `NOSHI_RAILS_MASTER_KEY`? The `MOAB/Production` vault already has `RAILS_MASTER_KEY` for moab. Use a distinct key name to avoid collision.

## Phase 3 — Deploy steps

1. Create ECR repo `moab/noshi` in the relevant region
2. Generate `NOSHI_SECRET_KEY_BASE` (`openssl rand -hex 64`) and add to 1Password vault `MOAB/Production`. App has no encrypted credentials — just needs this for cookie/CSRF signing.
3. Confirm Cloudflare origin cert covers `*.moab.jp` — re-issue if not
4. Confirm DNS `noshi.moab.jp` A-record → moab host, proxied through Cloudflare
5. Populate `.kamal/secrets` (gitignored) with real `DEPLOY_SERVER_IP`, `ECR_REGISTRY`, `ONE_PW_ACCOUNT` values
6. `bundle exec kamal setup` (first time)
7. `bundle exec kamal deploy`

## Recommended branch/commit structure

Cody preference TBD — choose one:

**Option A: three PRs (cleaner review)**
1. Rails 8 + Ruby 4 upgrade (`rails app:update` diff)
2. Strip frameworks + delete dead files
3. Kamal scaffolding + first deploy

**Option B: one branch (small app, all-or-nothing change anyway)**
- Single feature branch `kamal-deploy` with all phases.

## Resource footprint after all this

One ~150-200MB Rails container. No accessories. No DB. No Redis. Single web service on the existing moab server.

## Reference repos

- `~/dev/moab` — Rails Kamal pattern (Postgres accessory, ECR, 1Password, Cloudflare SSL, jemalloc)
- `~/dev/oroshi` — simpler/sandbox variant of same pattern
- `~/dev/brave-search-mcp-server-kamal` — non-Rails, but the cleanest example of the **Cloudflare origin cert SSL pattern** used here (https://github.com/cmbaldwin/brave-cozy-mcp.git)

## Status

- [x] PR #2 (御出産祝 → 御出産御祝) merged to main
- [x] Plan drafted
- [ ] Decision: 1 branch vs 3 PRs
- [ ] Phase 1 — strip Rails
- [ ] Phase 2 — Kamal scaffolding
- [ ] Phase 3 — first deploy
