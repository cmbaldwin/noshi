// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import NoshiPreview from "noshi_preview";

document.addEventListener("turbo:load", () => {
  new NoshiPreview(); // Reset NoshiPreview instance on server interaction

  const localeSelect = document.querySelector(".locale-select");
  if (localeSelect) {
    localeSelect.addEventListener("change", () => {
      const curHref = window.location.href
      const splitHref = curHref.split('/')
      const locale = localeSelect.value
      const root = `${window.location.protocol}//${splitHref[2]}`
      const newHref = `${root}/${locale}/${splitHref.slice(4).join('/')}`
      window.location.href = newHref
    });
  }
});
