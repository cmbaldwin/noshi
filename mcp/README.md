# Noshi MCP Server

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that exposes the [Noshi (熨斗)](https://noshi.moab.jp) Japanese gift-envelope generator as five AI-agent tools.

## Tools

| Tool | Description |
|---|---|
| `get_service_info` | Return API metadata, capabilities, and all endpoint URLs. Call first to orient the agent. |
| `list_occasions` | Return the complete list of selectable gift-occasion labels (表書き / omotegaki). |
| `list_designs` | Return all 21 built-in designs + approved community uploads, with thumbnails and orientation. |
| `list_backgrounds` | Browse community-uploaded backgrounds with star ratings. Sortable. |
| `compose_noshi` | Compose a noshi spec and receive a deep-link `editor_url` to the in-browser JPEG editor. |

## Requirements

- Node.js ≥ 18 (uses built-in `fetch` and ESM)

## Installation

```bash
cd mcp
npm install
```

## Usage

### Stdio transport (standard MCP)

```bash
node index.js
```

The server speaks JSON-RPC over stdin/stdout — the standard MCP transport.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `NOSHI_API_BASE_URL` | `https://noshi.moab.jp/api/v1` | Override to point at a local dev server. |

```bash
NOSHI_API_BASE_URL=http://localhost:3000/api/v1 node index.js
```

## Client configuration

### Claude Desktop

Add to `~/.claude/claude_desktop_config.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "noshi": {
      "command": "node",
      "args": ["/absolute/path/to/noshi/mcp/index.js"]
    }
  }
}
```

Restart Claude Desktop. The five Noshi tools will appear in Claude's tool list.

### Claude Code (CLI)

Add to your project's `.claude/settings.json`:

```json
{
  "mcpServers": {
    "noshi": {
      "command": "node",
      "args": ["mcp/index.js"]
    }
  }
}
```

Or register globally with:

```bash
claude mcp add noshi node mcp/index.js
```

### Generic MCP client

Any client that supports the MCP stdio transport can use this server. Pass the absolute path to `index.js` as the command argument.

## Testing

```bash
npm test
# or
node --test test/mcp.test.js
```

The test suite uses Node.js built-in `node:test` (no extra dependencies). All HTTP calls are intercepted by a mock — no live server required.

## Example agent interaction

```
Agent → list_occasions
← { "count": 97, "occasions": ["御祝", "御礼", "内祝", ...] }

Agent → compose_noshi({ omotegaki: "御祝", names: ["田中", "鈴木"], paper_size: "A4", ntype: 3 })
← {
    "spec": { "omotegaki": "御祝", "names": ["田中", "鈴木"], "paper_size": "A4", "ntype": 3, "orientation": "landscape" },
    "editor_url": "https://noshi.moab.jp/noshis/new/3/田中,鈴木/御祝",
    "instructions": "Open editor_url in a browser to preview, fine-tune, and download the print-ready JPEG.",
    "download": "In the editor, press 作成 / Create to download the JPEG."
  }

Agent → Share editor_url with user
User  → Opens URL, downloads JPEG
```

## API reference

All tools call the Noshi public REST API — see [`docs/api.md`](../docs/api.md) for the full reference and [`/api/v1/openapi.json`](https://noshi.moab.jp/api/v1/openapi.json) for the OpenAPI 3.0.3 spec.

## Architecture

```
mcp/
├── index.js          # MCP server + exported handlers (testable)
├── package.json
├── README.md
└── test/
    └── mcp.test.js   # Node built-in test runner, no extra deps
```

Key design decisions:
- `createNoshiServer(options)` is exported so tests can inject a mock `fetchFn` and custom `baseUrl` without running a real server.
- `handleTool(name, args, ctx)` and the individual `tool*` functions are also exported for fine-grained unit testing.
- The server only starts (connects transport) when the module is run as the entry point, not when imported.
