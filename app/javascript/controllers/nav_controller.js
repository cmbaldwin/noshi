import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mobileNav"];

  toggle() {
    if (!this.hasMobileNavTarget) return;

    const el = this.mobileNavTarget;
    el.classList.toggle("hidden");
  }
}
