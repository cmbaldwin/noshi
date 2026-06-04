// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import NoshiPreview from "noshi_preview";

// Bootstraps the live preview and the locale switcher.
//
// IMPORTANT: do not rely on `turbo:load` alone. This file is loaded as a
// deferred ES module via importmap, so in production (real network latency,
// Cloudflare/Thruster, modulepreload) Turbo frequently finishes starting up
// *after* the document has already loaded. When that happens Turbo never
// dispatches the initial `turbo:load`, and a listener that only waits for it
// never runs — which leaves the page with no working JavaScript at all (no
// preview, no locale switch). See test/javascript/smoke.test.mjs.
//
// So we run setup directly for the initial page load and let `turbo:load`
// handle subsequent Turbo-driven visits. setupPage() is idempotent, so it is
// safe even if both paths fire for the same render.
function setupPage() {
  const form = document.querySelector(".noshi_form");
  if (form && !form.dataset.previewBooted) {
    form.dataset.previewBooted = "true";
    new NoshiPreview(); // Reset NoshiPreview instance on server interaction
  }
  bindLocaleSelect();
}

function bindLocaleSelect() {
  const localeSelect = document.querySelector(".locale-select");
  if (!localeSelect || localeSelect.dataset.localeBound) return;
  localeSelect.dataset.localeBound = "true";

  localeSelect.addEventListener("change", () => {
    const splitHref = window.location.href.split("/");
    const locale = localeSelect.value;
    const root = `${window.location.protocol}//${splitHref[2]}`;
    window.location.href = `${root}/${locale}/${splitHref.slice(4).join("/")}`;
  });
}

// Subsequent Turbo visits (re-rendered DOM, so the idempotency guards reset).
document.addEventListener("turbo:load", setupPage);

// Initial page load. Covers the missed-initial-`turbo:load` case described above.
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", setupPage, { once: true });
} else {
  setupPage();
}
