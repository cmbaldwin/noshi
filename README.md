# 熨斗 Noshi

A bilingual Japanese/English web app for generating *noshi* (熨斗) — the decorative paper bands printed on Japanese gift envelopes (*noshigami*).

**Live:** [noshi.moab.jp](https://noshi.moab.jp)

---

## What it does

1. Choose a gift type (*omotegaki*) — e.g. 御祝、御礼、内祝
2. Enter recipient name(s)
3. Pick a visual style and paper size (A4/B5, portrait/landscape)
4. Preview live, then download a print-ready JPEG

No account needed. Nothing is saved. The noshi is generated entirely in your browser.

---

## Tech

- **Ruby 4.0 / Rails 8** — thin server, no database
- **Stimulus + Turbo** — live preview via canvas/DOM manipulation
- **Tailwind CSS** — styling
- **Importmap** — no Node.js, no bundler
- **Kamal 2** — deployed to a VPS via Docker

---

## Development

```bash
bin/setup   # install gems
bin/dev     # start local server (localhost:3000)
bin/rails test
```

Requires Ruby 4.0.0. No database setup needed.

---

## Deployment

```bash
kamal deploy
```

Requires:
- `config/ssl/cert.pem` and `config/ssl/key.pem` (Cloudflare origin cert, gitignored)
- `.kamal/secrets` populated (gitignored — see `.kamal/secrets` comments for what's needed)
- 1Password CLI signed in, AWS CLI configured

See [AGENTS.md](AGENTS.md) for full infrastructure and agent context.
