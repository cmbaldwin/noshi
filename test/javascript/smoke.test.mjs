// Browser smoke test for the Noshi generator's client-side JavaScript.
//
// Why this exists: the entire noshi UI (live preview, design/format switching,
// text positioning, and the JPEG download) is rendered client-side. The Ruby
// controller/model tests only assert on server-rendered HTML — they never
// execute a line of JavaScript, so they cannot catch "the JS doesn't run at
// all" regressions. This test drives a real headless browser to verify the JS
// actually works end to end.
//
// Usage:
//   BASE_URL=http://127.0.0.1:3001 node test/javascript/smoke.test.mjs
// (the `test:smoke` / `prebuild` rake tasks boot a server and set BASE_URL.)

import { chromium } from "playwright";

const BASE_URL = process.env.BASE_URL || process.argv[2] || "http://127.0.0.1:3001";

let failures = 0;
const results = [];

function check(name, condition, detail = "") {
  if (condition) {
    results.push(`  ✓ ${name}`);
  } else {
    failures++;
    results.push(`  ✗ ${name}${detail ? ` — ${detail}` : ""}`);
  }
}

async function newPage(browser, { suppressTurboLoad = false } = {}) {
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();
  const pageErrors = [];
  page.on("pageerror", (e) => pageErrors.push(e.message));
  page._pageErrors = pageErrors;
  if (suppressTurboLoad) {
    // Reproduce the production failure mode: Turbo boots from a deferred
    // importmap module after the document has already loaded, so the initial
    // `turbo:load` event is never delivered to the app. A correct app must
    // still bootstrap itself.
    await page.addInitScript(() => {
      document.addEventListener(
        "turbo:load",
        (e) => e.stopImmediatePropagation(),
        true
      );
    });
  }
  return page;
}

async function run() {
  const browser = await chromium.launch();
  try {
    // --- 1. Preview renders on a normal load -----------------------------
    {
      const page = await newPage(browser);
      await page.goto(`${BASE_URL}/`, { waitUntil: "load", timeout: 30000 });
      const rendered = await page
        .waitForSelector(".preview_paper", { timeout: 10000 })
        .then(() => true)
        .catch(() => false);
      check("preview renders on initial load", rendered);
      check(
        "no uncaught page errors on load",
        page._pageErrors.length === 0,
        page._pageErrors.join(" | ")
      );
      await page.context().close();
    }

    // --- 2. Preview renders even when `turbo:load` never fires ------------
    //     (the actual production regression this test was written for)
    {
      const page = await newPage(browser, { suppressTurboLoad: true });
      await page.goto(`${BASE_URL}/`, { waitUntil: "load", timeout: 30000 });
      const rendered = await page
        .waitForSelector(".preview_paper", { timeout: 10000 })
        .then(() => true)
        .catch(() => false);
      check(
        "preview renders without relying on turbo:load (prod regression)",
        rendered
      );
      await page.context().close();
    }

    // --- 3. Button / control functionality -------------------------------
    {
      const page = await newPage(browser);
      await page.goto(`${BASE_URL}/`, { waitUntil: "load", timeout: 30000 });
      await page.waitForSelector(".preview_paper", { timeout: 10000 });

      // Omotegaki quick-pick button writes into the preview.
      await page.click(".omotegaki_btn >> nth=0");
      await page.waitForTimeout(150);
      const omoText = (
        (await page.textContent(".preview_omotegaki_span")) || ""
      ).trim();
      check(
        "omotegaki button updates the preview text",
        omoText.length > 0 && omoText === (await page.inputValue("#noshi_omotegaki")),
        `preview=${JSON.stringify(omoText)}`
      );

      // Name input flows into the preview.
      await page.fill(".name_input >> nth=0", "山田太郎");
      await page.waitForTimeout(150);
      const nameShown = await page
        .locator(".preview_name", { hasText: "山田太郎" })
        .count();
      check("name input renders into the preview", nameShown > 0);

      // Switching paper format re-renders the preview without errors.
      await page.check('input.format_select[value="A4"]');
      await page.waitForTimeout(150);
      const stillThere = await page.locator(".preview_paper").count();
      check("format switch keeps a rendered preview", stillThere === 1);

      // Position nudge buttons don't throw.
      await page.check('input.format_select[value="B5"]');
      await page.waitForTimeout(100);
      await page.click(".omotegaki-up");
      await page.click(".names-down");
      await page.waitForTimeout(100);
      check(
        "position nudge buttons run without errors",
        page._pageErrors.length === 0,
        page._pageErrors.join(" | ")
      );

      // Nav (Stimulus) toggle flips the mobile menu's hidden state. The
      // hamburger is only shown at mobile widths (lg:hidden), so shrink first.
      await page.setViewportSize({ width: 375, height: 800 });
      const navTarget = page.locator('[data-nav-target="mobileNav"]');
      const beforeHidden = await navTarget.evaluate((el) =>
        el.classList.contains("hidden")
      );
      await page.click('[data-action="nav#toggle"]');
      await page.waitForTimeout(100);
      const afterHidden = await navTarget.evaluate((el) =>
        el.classList.contains("hidden")
      );
      check("nav toggle (Stimulus) flips menu visibility", beforeHidden !== afterHidden);

      await page.context().close();
    }

    // --- 4. Download button produces a downloadable image ----------------
    {
      const page = await newPage(browser);
      await page.goto(`${BASE_URL}/`, { waitUntil: "load", timeout: 30000 });
      await page.waitForSelector(".preview_paper", { timeout: 10000 });

      // Click "Create" — opens the modal and renders the preview to a JPEG,
      // wiring the result into the .noshi_download link's href.
      await page.click("#create_now");

      const modalShown = await page
        .waitForSelector(".noshi-modal:not(.hidden)", { timeout: 8000 })
        .then(() => true)
        .catch(() => false);
      check("create button opens the download modal", modalShown);

      // html-to-image runs asynchronously; wait for the link to receive a
      // data: URL (this also confirms window.htmlToImage loaded from the CDN).
      const hrefOk = await page
        .waitForFunction(
          () => {
            const a = document.querySelector(".noshi_download");
            return a && a.getAttribute("href") && a.getAttribute("href").startsWith("data:image");
          },
          { timeout: 20000 }
        )
        .then(() => true)
        .catch(() => false);
      check("download link receives a generated image (data: URL)", hrefOk);

      const imgShown = await page.locator("#noshi_download_preview img").count();
      check("generated image preview is shown in the modal", imgShown > 0);

      check(
        "no uncaught page errors during download",
        page._pageErrors.length === 0,
        page._pageErrors.join(" | ")
      );

      await page.context().close();
    }
  } finally {
    await browser.close();
  }
}

run()
  .then(() => {
    console.log(`\nJS smoke test against ${BASE_URL}`);
    console.log(results.join("\n"));
    if (failures > 0) {
      console.error(`\n✗ ${failures} JS smoke check(s) failed.`);
      process.exit(1);
    }
    console.log("\n✓ All JS smoke checks passed.");
  })
  .catch((err) => {
    console.error("JS smoke test crashed:", err);
    process.exit(1);
  });
