# Noshi API — Reference

> **Base URL:** `https://noshi.moab.jp/api/v1`
> **OpenAPI spec:** `GET /api/v1/openapi.json`
> **MCP server:** [`mcp/`](../mcp/README.md)

The Noshi public API is **read-only, CORS-open, and requires no authentication**. It is designed to be consumed directly by AI agents, browser clients, and integrations.

---

## At a glance

| Endpoint | Purpose |
|---|---|
| `GET /api/v1` | Service manifest — capabilities and endpoint map |
| `GET /api/v1/omotegaki` | Selectable gift-occasion labels (表書き) |
| `GET /api/v1/designs` | Built-in and community background designs |
| `GET /api/v1/backgrounds` | Approved community uploads with ratings |
| `GET /api/v1/noshi` | Compose a spec and receive a deep-link editor URL |
| `GET /api/v1/openapi.json` | OpenAPI 3.0.3 spec (machine-readable) |

---

## CORS

All endpoints return:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
```

No preflight is needed for standard GET requests from browsers or agents.

---

## Endpoints

### `GET /api/v1` — Service manifest

Returns service metadata including capabilities and a map of all endpoint URLs.
**AI agents: call this first** to self-orient before using other endpoints.

**Response shape:**

```json
{
  "name": "Noshi (熨斗) Generator API",
  "description": "...",
  "version": "1",
  "website": "https://noshi.moab.jp",
  "documentation": "https://noshi.moab.jp/llms.txt",
  "locales": ["ja", "en"],
  "capabilities": {
    "paper_sizes": ["B5", "A4", "縦B5", "縦A4"],
    "max_names": 5,
    "builtin_designs": 21,
    "rendering": "client-side — the editor renders and downloads a print-ready JPEG in the browser"
  },
  "endpoints": {
    "service":     "https://noshi.moab.jp/api/v1",
    "occasions":   "https://noshi.moab.jp/api/v1/omotegaki",
    "designs":     "https://noshi.moab.jp/api/v1/designs",
    "backgrounds": "https://noshi.moab.jp/api/v1/backgrounds",
    "compose":     "https://noshi.moab.jp/api/v1/noshi?omotegaki={occasion}&names={name1,name2}&paper_size={B5|A4|縦B5|縦A4}&ntype={1-21}",
    "openapi":     "https://noshi.moab.jp/api/v1/openapi.json"
  }
}
```

---

### `GET /api/v1/omotegaki` — List occasions

Returns all selectable gift-occasion labels (表書き / omotegaki). Category separator entries are excluded.

**Response shape:**

```json
{
  "count": 97,
  "occasions": ["御祝", "寿", "祝御結婚", "内祝", "御出産御祝", "御霊前", ...]
}
```

**Usage:** Pass a value from `occasions[]` as the `omotegaki` query parameter to `/noshi`.

---

### `GET /api/v1/designs` — List designs

Returns the 21 built-in noshi background designs plus any approved community uploads.

| ntype | Orientation |
|---|---|
| 1–14 | landscape |
| 15–21 | portrait |

**Response shape:**

```json
{
  "builtin": [
    {
      "ntype": 1,
      "orientation": "landscape",
      "thumbnail_url": "https://noshi.moab.jp/assets/noshi/thumbs/noshi1-thumb-abc123.jpg",
      "image_url":     "https://noshi.moab.jp/assets/noshi/noshi1-abc123.jpg"
    }
  ],
  "community": [
    {
      "id": 12,
      "title": "Cherry Blossoms",
      "description": "Pink sakura pattern",
      "orientation": "landscape",
      "average_rating": 4.5,
      "ratings_count": 8,
      "uploaded_by": "山田",
      "image_url": "https://noshi.moab.jp/rails/active_storage/blobs/..."
    }
  ]
}
```

**Usage:** Use `ntype` from `builtin[]` or `id` from `community[]` to select a design, then pass `ntype` to `/noshi`.

---

### `GET /api/v1/backgrounds` — Community backgrounds

Returns only approved community-uploaded backgrounds with ratings.

**Query parameters:**

| Name | Type | Default | Description |
|---|---|---|---|
| `sort` | string | `top_rated` | `top_rated` (highest average rating first) or `new` (newest first) |

**Response shape:**

```json
{
  "count": 3,
  "backgrounds": [
    {
      "id": 12,
      "title": "Cherry Blossoms",
      "description": "Pink sakura pattern",
      "orientation": "landscape",
      "average_rating": 4.5,
      "ratings_count": 8,
      "uploaded_by": "山田",
      "image_url": "https://noshi.moab.jp/rails/active_storage/blobs/..."
    }
  ]
}
```

---

### `GET /api/v1/noshi` — Compose a noshi

Normalizes inputs and returns a deep-link `editor_url`. Open that URL in a browser to preview, fine-tune, and download the print-ready JPEG. All parameters are optional.

**Query parameters:**

| Name | Type | Default | Description |
|---|---|---|---|
| `omotegaki` | string | `""` | Gift-occasion label. Values from `/omotegaki`. |
| `names` | string | `""` | Comma-separated recipient names, up to 5. |
| `paper_size` | string | `B5` | One of: `B5`, `A4`, `縦B5`, `縦A4`. |
| `ntype` | integer | `1` | Design 1–21. Out-of-range values are clamped. |

**Response shape:**

```json
{
  "spec": {
    "omotegaki": "御祝",
    "names": ["田中", "鈴木"],
    "paper_size": "A4",
    "ntype": 3,
    "orientation": "landscape"
  },
  "editor_url": "https://noshi.moab.jp/noshis/new/3/%E7%94%B0%E4%B8%AD%2C%E9%88%B4%E6%9C%A8/%E5%BE%A1%E7%A5%9D",
  "instructions": "Open editor_url in a browser to preview, fine-tune, and download the print-ready JPEG. Rendering happens client-side; no account is required.",
  "download": "In the editor, press 作成 / Create to download the JPEG."
}
```

**Notes:**
- If `names` is empty or `omotegaki` is blank, `editor_url` points at the empty editor root (`/`).
- The JPEG is rendered in the browser — the API does not serve images directly.

---

### `GET /api/v1/openapi.json` — OpenAPI spec

Returns the full [OpenAPI 3.0.3](https://spec.openapis.org/oas/v3.0.3) specification for this API in JSON. Suitable for import into Swagger UI, Postman, code generators, and AI tool frameworks.

---

## AI agent workflow

Recommended call sequence for an AI agent composing a noshi:

```
1. GET /api/v1           → Understand capabilities; find endpoint URLs
2. GET /api/v1/omotegaki → Present occasion choices to the user
3. GET /api/v1/designs   → Present design choices (ntype + thumbnails)
4. GET /api/v1/noshi     → Compose spec; receive editor_url
5. Share editor_url      → User opens in browser, downloads JPEG
```

**Minimal example (with defaults):**

```
GET https://noshi.moab.jp/api/v1/noshi?omotegaki=御祝&names=田中,鈴木&paper_size=A4&ntype=3
```

**Response:**

```json
{
  "spec": { "omotegaki": "御祝", "names": ["田中", "鈴木"], "paper_size": "A4", "ntype": 3, "orientation": "landscape" },
  "editor_url": "https://noshi.moab.jp/noshis/new/3/田中,鈴木/御祝",
  "instructions": "Open editor_url in a browser...",
  "download": "Press 作成 / Create to download the JPEG."
}
```

---

## MCP server

For AI agents that use the Model Context Protocol, a ready-made MCP server wraps all five endpoints as tools:

```
mcp/
├── index.js    # MCP server (stdio transport)
├── README.md   # Setup and usage
└── test/
    └── mcp.test.js
```

See [`mcp/README.md`](../mcp/README.md) for installation instructions and Claude Desktop / Claude Code configuration.

---

## Deep-link format (without the API)

You can also construct editor links directly without calling the API:

```
https://noshi.moab.jp/noshis/new/{ntype}/{names}/{omotegaki}
```

All three path segments must be URL-encoded. Example:

```
https://noshi.moab.jp/noshis/new/1/田中/御祝
```

---

## Locale

The editor supports Japanese (`/ja/`) and English (`/en/`). The API itself has no locale parameter — it returns data in Japanese regardless.
