/**
 * Noshi MCP Server — test suite
 *
 * Uses Node.js built-in test runner (no extra dependencies).
 * Run: node --test test/mcp.test.js   (from the mcp/ directory)
 *   or: npm test                       (from the mcp/ directory)
 *
 * All HTTP calls are intercepted by a mock fetch — no live server needed.
 */

import { describe, test } from "node:test";
import assert from "node:assert/strict";

import {
  TOOLS,
  handleTool,
  createNoshiServer,
  toolGetServiceInfo,
  toolListOccasions,
  toolListDesigns,
  toolListBackgrounds,
  toolComposeNoshi,
} from "../index.js";

// ─────────────────────────────────────────────────────────────────────────────
// Mock API responses (mirrors the real Rails API response shapes)
// ─────────────────────────────────────────────────────────────────────────────

const BASE = "https://mock.noshi/api/v1";

const MOCK = {
  service: {
    name: "Noshi (熨斗) Generator API",
    description: "Build Japanese gift-envelope noshi.",
    version: "1",
    website: "https://noshi.moab.jp",
    documentation: "https://noshi.moab.jp/llms.txt",
    locales: ["ja", "en"],
    capabilities: {
      paper_sizes: ["B5", "A4", "縦B5", "縦A4"],
      max_names: 5,
      builtin_designs: 21,
      rendering: "client-side",
    },
    endpoints: {
      service: `${BASE}`,
      occasions: `${BASE}/omotegaki`,
      designs: `${BASE}/designs`,
      backgrounds: `${BASE}/backgrounds`,
      compose: `${BASE}/noshi?omotegaki={occasion}&names={name1,name2}&paper_size={B5|A4|縦B5|縦A4}&ntype={1-21}`,
      openapi: `${BASE}/openapi.json`,
    },
  },
  omotegaki: {
    count: 4,
    occasions: ["御祝", "御礼", "内祝", "御中元"],
  },
  designs: {
    builtin: [
      { ntype: 1, orientation: "landscape", thumbnail_url: "https://x/t1.jpg", image_url: "https://x/i1.jpg" },
      { ntype: 7, orientation: "landscape", thumbnail_url: "https://x/t7.jpg", image_url: "https://x/i7.jpg" },
      { ntype: 15, orientation: "portrait", thumbnail_url: "https://x/t15.jpg", image_url: "https://x/i15.jpg" },
      { ntype: 21, orientation: "portrait", thumbnail_url: "https://x/t21.jpg", image_url: "https://x/i21.jpg" },
    ],
    community: [
      {
        id: 42,
        title: "Cherry Blossoms",
        description: "Pink sakura background",
        orientation: "landscape",
        average_rating: 4.5,
        ratings_count: 12,
        uploaded_by: "Tanaka",
        image_url: "https://x/cherry.jpg",
      },
    ],
  },
  backgrounds: {
    count: 1,
    backgrounds: [
      {
        id: 42,
        title: "Cherry Blossoms",
        description: "Pink sakura background",
        orientation: "landscape",
        average_rating: 4.5,
        ratings_count: 12,
        uploaded_by: "Tanaka",
        image_url: "https://x/cherry.jpg",
      },
    ],
  },
};

/** Simulate a successful fetch response for the given data. */
function ok(data) {
  return Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve(data) });
}

/**
 * Mock fetch that routes by pathname and generates /noshi responses dynamically
 * so tests don't need to predict exact URL-encoding.
 */
function mockFetch(url) {
  const u = new URL(url);

  if (u.pathname === "/api/v1" || u.pathname === "/api/v1/") {
    return ok(MOCK.service);
  }
  if (u.pathname === "/api/v1/omotegaki") {
    return ok(MOCK.omotegaki);
  }
  if (u.pathname === "/api/v1/designs") {
    return ok(MOCK.designs);
  }
  if (u.pathname === "/api/v1/backgrounds") {
    return ok(MOCK.backgrounds);
  }
  if (u.pathname === "/api/v1/noshi") {
    const omotegaki = u.searchParams.get("omotegaki") ?? "";
    const rawNames = u.searchParams.get("names") ?? "";
    const names = rawNames.split(",").map((s) => s.trim()).filter(Boolean);
    const paper_size = u.searchParams.get("paper_size") ?? "B5";
    const ntype = Number(u.searchParams.get("ntype") ?? "1");
    const orientation = ntype <= 14 ? "landscape" : "portrait";

    return ok({
      spec: { omotegaki, names, paper_size, ntype, orientation },
      editor_url:
        names.length && omotegaki
          ? `https://noshi.moab.jp/noshis/new/${ntype}/${names.join(",")}/${encodeURIComponent(omotegaki)}`
          : "https://noshi.moab.jp",
      instructions:
        "Open editor_url in a browser to preview, fine-tune, and download the print-ready JPEG.",
      download: "In the editor, press 作成 / Create to download the JPEG.",
    });
  }

  throw new Error(`mockFetch: unexpected URL: ${url}`);
}

const ctx = { baseUrl: BASE, fetchFn: mockFetch };

// ─────────────────────────────────────────────────────────────────────────────
// Tool definition tests
// ─────────────────────────────────────────────────────────────────────────────

describe("TOOLS definitions", () => {
  test("exports exactly 5 tools", () => {
    assert.equal(TOOLS.length, 5);
  });

  test("tool names match the expected set", () => {
    const names = TOOLS.map((t) => t.name).sort();
    assert.deepEqual(names, [
      "compose_noshi",
      "get_service_info",
      "list_backgrounds",
      "list_designs",
      "list_occasions",
    ]);
  });

  test("every tool has a non-empty name", () => {
    for (const tool of TOOLS) {
      assert.ok(typeof tool.name === "string" && tool.name.length > 0, `tool missing name`);
    }
  });

  test("every tool has a meaningful description (>20 chars)", () => {
    for (const tool of TOOLS) {
      assert.ok(
        typeof tool.description === "string" && tool.description.length > 20,
        `${tool.name}: description too short`
      );
    }
  });

  test("every tool has a valid inputSchema of type object", () => {
    for (const tool of TOOLS) {
      assert.ok(
        tool.inputSchema && typeof tool.inputSchema === "object",
        `${tool.name}: missing inputSchema`
      );
      assert.equal(tool.inputSchema.type, "object", `${tool.name}: inputSchema.type must be "object"`);
      assert.ok(
        Array.isArray(tool.inputSchema.required),
        `${tool.name}: inputSchema.required must be an array`
      );
    }
  });

  test("compose_noshi inputSchema documents all expected parameters", () => {
    const composeTool = TOOLS.find((t) => t.name === "compose_noshi");
    assert.ok(composeTool, "compose_noshi tool not found");
    const props = Object.keys(composeTool.inputSchema.properties);
    assert.ok(props.includes("omotegaki"), "missing omotegaki param");
    assert.ok(props.includes("names"), "missing names param");
    assert.ok(props.includes("paper_size"), "missing paper_size param");
    assert.ok(props.includes("ntype"), "missing ntype param");
  });

  test("list_backgrounds inputSchema documents sort parameter", () => {
    const bgTool = TOOLS.find((t) => t.name === "list_backgrounds");
    assert.ok(bgTool, "list_backgrounds tool not found");
    assert.ok(bgTool.inputSchema.properties.sort, "missing sort param");
    assert.deepEqual(bgTool.inputSchema.properties.sort.enum, ["top_rated", "new"]);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Individual handler tests (using exported helpers directly)
// ─────────────────────────────────────────────────────────────────────────────

describe("toolGetServiceInfo", () => {
  test("returns service name and version", async () => {
    const result = await toolGetServiceInfo(ctx);
    assert.equal(result.name, "Noshi (熨斗) Generator API");
    assert.equal(result.version, "1");
  });

  test("capabilities include all expected paper sizes", async () => {
    const result = await toolGetServiceInfo(ctx);
    assert.deepEqual(result.capabilities.paper_sizes, ["B5", "A4", "縦B5", "縦A4"]);
  });

  test("max_names is 5", async () => {
    const result = await toolGetServiceInfo(ctx);
    assert.equal(result.capabilities.max_names, 5);
  });

  test("endpoints map contains all known endpoints", async () => {
    const result = await toolGetServiceInfo(ctx);
    const keys = Object.keys(result.endpoints);
    assert.ok(keys.includes("occasions"), "missing occasions endpoint");
    assert.ok(keys.includes("designs"), "missing designs endpoint");
    assert.ok(keys.includes("compose"), "missing compose endpoint");
  });
});

describe("toolListOccasions", () => {
  test("returns occasions array", async () => {
    const result = await toolListOccasions(ctx);
    assert.ok(Array.isArray(result.occasions));
    assert.equal(result.count, result.occasions.length);
  });

  test("occasions include 御祝", async () => {
    const result = await toolListOccasions(ctx);
    assert.ok(result.occasions.includes("御祝"), "御祝 should be in the list");
  });

  test("count field matches array length", async () => {
    const result = await toolListOccasions(ctx);
    assert.equal(result.count, result.occasions.length);
  });
});

describe("toolListDesigns", () => {
  test("returns builtin and community arrays", async () => {
    const result = await toolListDesigns(ctx);
    assert.ok(Array.isArray(result.builtin), "builtin should be an array");
    assert.ok(Array.isArray(result.community), "community should be an array");
  });

  test("builtin designs have required fields", async () => {
    const result = await toolListDesigns(ctx);
    for (const d of result.builtin) {
      assert.ok(typeof d.ntype === "number", `ntype missing in design ${JSON.stringify(d)}`);
      assert.ok(["landscape", "portrait"].includes(d.orientation), `bad orientation: ${d.orientation}`);
      assert.ok(typeof d.thumbnail_url === "string");
      assert.ok(typeof d.image_url === "string");
    }
  });

  test("ntype 1 is landscape", async () => {
    const result = await toolListDesigns(ctx);
    const d = result.builtin.find((b) => b.ntype === 1);
    assert.ok(d, "ntype 1 not found");
    assert.equal(d.orientation, "landscape");
  });

  test("ntype 15 is portrait", async () => {
    const result = await toolListDesigns(ctx);
    const d = result.builtin.find((b) => b.ntype === 15);
    assert.ok(d, "ntype 15 not found");
    assert.equal(d.orientation, "portrait");
  });

  test("community uploads have title and orientation", async () => {
    const result = await toolListDesigns(ctx);
    for (const bg of result.community) {
      assert.ok(typeof bg.title === "string" && bg.title.length > 0);
      assert.ok(["landscape", "portrait"].includes(bg.orientation));
    }
  });
});

describe("toolListBackgrounds", () => {
  test("returns backgrounds array with count", async () => {
    const result = await toolListBackgrounds(ctx);
    assert.ok(typeof result.count === "number");
    assert.ok(Array.isArray(result.backgrounds));
    assert.equal(result.count, result.backgrounds.length);
  });

  test("backgrounds have rating fields", async () => {
    const result = await toolListBackgrounds(ctx);
    for (const bg of result.backgrounds) {
      assert.ok(typeof bg.average_rating === "number");
      assert.ok(typeof bg.ratings_count === "number");
    }
  });

  test("sort=new parameter is forwarded without error", async () => {
    const result = await toolListBackgrounds({ ...ctx, sort: "new" });
    assert.ok(result, "should return a result");
    assert.ok(Array.isArray(result.backgrounds));
  });
});

describe("toolComposeNoshi", () => {
  test("returns spec and editor_url", async () => {
    const result = await toolComposeNoshi({
      ...ctx,
      args: { omotegaki: "御祝", names: ["田中"], paper_size: "B5", ntype: 1 },
    });
    assert.ok(result.spec, "should have spec");
    assert.ok(typeof result.editor_url === "string" && result.editor_url.startsWith("http"));
  });

  test("spec reflects provided omotegaki", async () => {
    const result = await toolComposeNoshi({
      ...ctx,
      args: { omotegaki: "御礼", names: ["山田"], paper_size: "A4", ntype: 3 },
    });
    assert.equal(result.spec.omotegaki, "御礼");
    assert.deepEqual(result.spec.names, ["山田"]);
    assert.equal(result.spec.paper_size, "A4");
    assert.equal(result.spec.ntype, 3);
  });

  test("editor_url is a deep link when names and omotegaki provided", async () => {
    const result = await toolComposeNoshi({
      ...ctx,
      args: { omotegaki: "御祝", names: ["田中", "鈴木"] },
    });
    assert.ok(result.editor_url.includes("/noshis/new/"), "should be a deep link");
  });

  test("empty args still returns a valid response", async () => {
    const result = await toolComposeNoshi({ ...ctx, args: {} });
    assert.ok(result.spec, "should return a spec");
    assert.ok(result.editor_url, "should always return an editor_url");
  });

  test("ntype 1–14 produces landscape orientation", async () => {
    const result = await toolComposeNoshi({ ...ctx, args: { ntype: 1 } });
    assert.equal(result.spec.orientation, "landscape");
  });

  test("ntype 15–21 produces portrait orientation", async () => {
    const result = await toolComposeNoshi({ ...ctx, args: { ntype: 15 } });
    assert.equal(result.spec.orientation, "portrait");
  });

  test("returns user instructions", async () => {
    const result = await toolComposeNoshi({ ...ctx, args: { omotegaki: "内祝" } });
    assert.ok(typeof result.instructions === "string" && result.instructions.length > 0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// handleTool dispatch
// ─────────────────────────────────────────────────────────────────────────────

describe("handleTool dispatch", () => {
  test("routes get_service_info", async () => {
    const result = await handleTool("get_service_info", {}, ctx);
    assert.equal(result.version, "1");
  });

  test("routes list_occasions", async () => {
    const result = await handleTool("list_occasions", {}, ctx);
    assert.ok(Array.isArray(result.occasions));
  });

  test("routes list_designs", async () => {
    const result = await handleTool("list_designs", {}, ctx);
    assert.ok(Array.isArray(result.builtin));
  });

  test("routes list_backgrounds", async () => {
    const result = await handleTool("list_backgrounds", {}, ctx);
    assert.ok(Array.isArray(result.backgrounds));
  });

  test("routes compose_noshi", async () => {
    const result = await handleTool("compose_noshi", { omotegaki: "御祝" }, ctx);
    assert.ok(result.editor_url);
  });

  test("throws for unknown tool", async () => {
    await assert.rejects(
      () => handleTool("does_not_exist", {}, ctx),
      { message: "Unknown tool: does_not_exist" }
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Server-level error handling (via createNoshiServer + handleTool)
// ─────────────────────────────────────────────────────────────────────────────

describe("error handling", () => {
  test("propagates API HTTP error with status code in message", async () => {
    const failFetch = () => Promise.resolve({ ok: false, status: 503 });
    await assert.rejects(
      () => handleTool("get_service_info", {}, { baseUrl: BASE, fetchFn: failFetch }),
      /503/
    );
  });

  test("propagates network failure", async () => {
    const networkFail = () => Promise.reject(new Error("ECONNREFUSED"));
    await assert.rejects(
      () => handleTool("list_occasions", {}, { baseUrl: BASE, fetchFn: networkFail }),
      /ECONNREFUSED/
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// createNoshiServer
// ─────────────────────────────────────────────────────────────────────────────

describe("createNoshiServer", () => {
  test("returns an object with a connect method", () => {
    const server = createNoshiServer({ baseUrl: BASE, fetchFn: mockFetch });
    assert.ok(server !== null && typeof server === "object", "should return an object");
    assert.ok(typeof server.connect === "function", "should have a connect method");
  });

  test("returns an object with setRequestHandler method", () => {
    const server = createNoshiServer({ baseUrl: BASE, fetchFn: mockFetch });
    assert.ok(typeof server.setRequestHandler === "function");
  });
});
