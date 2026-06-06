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
    applySavedSettings();
  }
  bindLocaleSelect();
}

// When the generator was opened from a saved noshi, the server embeds its
// settings as JSON. Re-apply them to the form by driving the same events the
// live preview already listens to, so the design is reproduced without
// re-instantiating (and double-binding) the preview.
function applySavedSettings() {
  const el = document.querySelector("#saved_noshi_settings");
  if (!el || el.dataset.applied) return;
  el.dataset.applied = "true";

  let s;
  try {
    s = JSON.parse(el.textContent);
  } catch {
    return;
  }

  const fire = (node, type) =>
    node && node.dispatchEvent(new Event(type, { bubbles: true }));

  if (s.paper_size) {
    const radio = document.querySelector(
      `input[name="noshi[paper_size]"][value="${s.paper_size}"]`
    );
    if (radio) {
      radio.checked = true;
      fire(radio, "change");
    }
  }
  // Select the design tile. A saved community upload is identified by its stable
  // background_id; if that tile is gone (deleted/unapproved) we leave the default
  // design rather than guessing — the server shows a "background removed" warning.
  // Built-in designs use the positional index: tile ids are the 0-based noshiId,
  // while the saved ntype is noshiId + 1 (the form's design number).
  let designTile = null;
  if (s.background_id != null) {
    designTile = document.querySelector(
      `#noshi_design_list [data-background-id="${s.background_id}"]`
    );
  } else if (s.ntype != null) {
    designTile = document.querySelector(`#list-noshi-${Number(s.ntype) - 1}`);
  }
  designTile?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
  if (s.omotegaki != null) {
    const txt = document.querySelector("#noshi_omotegaki");
    if (txt) {
      txt.value = s.omotegaki;
      fire(txt, "input");
    }
  }
  if (s.omotegaki_size != null) {
    const r = document.querySelector(".omotegaki_size_select");
    if (r) {
      r.value = s.omotegaki_size;
      fire(r, "change");
    }
  }
  if (Array.isArray(s.names)) {
    document.querySelectorAll(".name_input").forEach((inp) => {
      inp.value = s.names[Number(inp.dataset.index)] ?? "";
      fire(inp, "input");
    });
  }
  if (s.font_size != null) {
    const r = document.querySelector(".font_size");
    if (r) {
      r.value = s.font_size;
      fire(r, "change");
    }
  }
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
