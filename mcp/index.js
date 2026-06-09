#!/usr/bin/env node
/**
 * Noshi MCP Server
 *
 * Exposes the Noshi (熨斗) Generator API as MCP tools so AI agents can:
 *   1. Discover what occasions, designs, and paper sizes are available.
 *   2. Compose a noshi spec and receive a deep-link editor URL.
 *   3. Browse community-uploaded backgrounds.
 *
 * Usage:
 *   node mcp/index.js                    # run via stdio (default MCP transport)
 *   NOSHI_API_BASE_URL=http://localhost:3000/api/v1 node mcp/index.js
 *
 * Claude Desktop config (~/.claude/claude_desktop_config.json):
 *   {
 *     "mcpServers": {
 *       "noshi": {
 *         "command": "node",
 *         "args": ["/absolute/path/to/noshi/mcp/index.js"]
 *       }
 *     }
 *   }
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { fileURLToPath } from "node:url";

const DEFAULT_BASE_URL =
  process.env.NOSHI_API_BASE_URL ?? "https://noshi.moab.jp/api/v1";

// ─────────────────────────────────────────────────────────────────────────────
// Tool definitions (JSON Schema for inputs)
// ─────────────────────────────────────────────────────────────────────────────

/** @type {import("@modelcontextprotocol/sdk/types.js").Tool[]} */
export const TOOLS = [
  {
    name: "get_service_info",
    description:
      "Return metadata about the Noshi API: name, version, capabilities " +
      "(paper sizes, max names, design count), and a map of all endpoint URLs. " +
      "Call this first to understand what the API offers before using other tools.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
  },
  {
    name: "list_occasions",
    description:
      "Return the complete list of selectable gift-occasion labels (表書き / omotegaki). " +
      "Examples: 御祝 (celebration), 御礼 (gratitude), 内祝 (return gift), 御中元 (mid-year gift). " +
      "Pass the chosen label as the `omotegaki` argument to compose_noshi.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
  },
  {
    name: "list_designs",
    description:
      "Return all available noshi background designs: the 21 built-in designs (ntype 1–21) " +
      "plus any approved community uploads. " +
      "Each entry includes `ntype` (pass to compose_noshi), `orientation` " +
      "(landscape for ntype 1–14, portrait for 15–21), and image/thumbnail URLs.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
  },
  {
    name: "list_backgrounds",
    description:
      "Return approved community-uploaded background images with their star ratings. " +
      "Useful for browsing or recommending custom backgrounds to users.",
    inputSchema: {
      type: "object",
      properties: {
        sort: {
          type: "string",
          enum: ["top_rated", "new"],
          description:
            'Sort order: "top_rated" (default, highest average rating first) ' +
            'or "new" (newest upload first).',
        },
      },
      required: [],
    },
  },
  {
    name: "compose_noshi",
    description:
      "Compose a noshi spec from the given parameters and return an `editor_url`. " +
      "Open that URL in a browser to preview, fine-tune, and download the print-ready JPEG. " +
      "JPEG rendering happens client-side — no account is required. " +
      "All parameters are optional; omitting them opens the empty editor.",
    inputSchema: {
      type: "object",
      properties: {
        omotegaki: {
          type: "string",
          description:
            "Gift-occasion label (表書き), e.g. 御祝, 御礼, 内祝. " +
            "Get the full list from list_occasions.",
        },
        names: {
          type: "array",
          items: { type: "string" },
          description:
            "Recipient name(s). Up to 5. Japanese or English strings.",
          maxItems: 5,
        },
        paper_size: {
          type: "string",
          enum: ["B5", "A4", "縦B5", "縦A4"],
          description:
            'Paper size. "B5" and "A4" are landscape-oriented; ' +
            '"縦B5" and "縦A4" are portrait-oriented. Defaults to B5.',
        },
        ntype: {
          type: "integer",
          minimum: 1,
          maximum: 21,
          description:
            "Design number (1–21). Get the full catalog from list_designs. " +
            "Designs 1–14 are landscape; 15–21 are portrait.",
        },
      },
      required: [],
    },
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// API client helpers
// ─────────────────────────────────────────────────────────────────────────────

async function apiFetch(url, fetchFn) {
  const res = await fetchFn(url);
  if (!res.ok) {
    throw new Error(`Noshi API error ${res.status} for ${url}`);
  }
  return res.json();
}

export async function toolGetServiceInfo({ baseUrl, fetchFn }) {
  return apiFetch(baseUrl, fetchFn);
}

export async function toolListOccasions({ baseUrl, fetchFn }) {
  return apiFetch(`${baseUrl}/omotegaki`, fetchFn);
}

export async function toolListDesigns({ baseUrl, fetchFn }) {
  return apiFetch(`${baseUrl}/designs`, fetchFn);
}

export async function toolListBackgrounds({ baseUrl, fetchFn, sort = "top_rated" }) {
  const url = new URL(`${baseUrl}/backgrounds`);
  if (sort && sort !== "top_rated") url.searchParams.set("sort", sort);
  return apiFetch(url.toString(), fetchFn);
}

export async function toolComposeNoshi({ baseUrl, fetchFn, args }) {
  const url = new URL(`${baseUrl}/noshi`);
  if (args.omotegaki) url.searchParams.set("omotegaki", args.omotegaki);
  if (args.names?.length) url.searchParams.set("names", args.names.join(","));
  if (args.paper_size) url.searchParams.set("paper_size", args.paper_size);
  if (args.ntype != null) url.searchParams.set("ntype", String(args.ntype));
  return apiFetch(url.toString(), fetchFn);
}

/**
 * Route a named tool call to the appropriate handler.
 * Exported so tests can invoke handlers directly with a mock fetchFn.
 *
 * @param {string} name - Tool name
 * @param {object} args - Tool arguments
 * @param {{ baseUrl: string, fetchFn: Function }} ctx - Runtime context
 */
export async function handleTool(name, args, { baseUrl, fetchFn }) {
  switch (name) {
    case "get_service_info":
      return toolGetServiceInfo({ baseUrl, fetchFn });
    case "list_occasions":
      return toolListOccasions({ baseUrl, fetchFn });
    case "list_designs":
      return toolListDesigns({ baseUrl, fetchFn });
    case "list_backgrounds":
      return toolListBackgrounds({ baseUrl, fetchFn, sort: args.sort });
    case "compose_noshi":
      return toolComposeNoshi({ baseUrl, fetchFn, args });
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server factory
// Accepts optional baseUrl and fetchFn overrides — used by tests.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Create and return a configured MCP Server instance.
 *
 * @param {{ baseUrl?: string, fetchFn?: Function }} options
 * @returns {import("@modelcontextprotocol/sdk/server/index.js").Server}
 */
export function createNoshiServer(options = {}) {
  const { baseUrl = DEFAULT_BASE_URL, fetchFn = globalThis.fetch } = options;

  const server = new Server(
    { name: "noshi-mcp-server", version: "1.0.0" },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args = {} } = request.params;
    try {
      const result = await handleTool(name, args, { baseUrl, fetchFn });
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  });

  return server;
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — only executes when invoked directly, not when imported
// ─────────────────────────────────────────────────────────────────────────────

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const server = createNoshiServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
}
