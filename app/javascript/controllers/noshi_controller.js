import { Controller } from "@hotwired/stimulus";

import * as htmlToImage from "html-to-image";

export default class extends Controller {
  static targets = [];

  collapseToggle(e) {
    e.preventDefault();
    if (!e.target.dataset.target) return false;

    document
      .querySelector(`#${e.target.dataset.target}`)
      .classList.toggle("hidden");
  }

  createImage(e) {
    e.preventDefault();
    this.appendSpinner();
    this.toggleModal();
    this.previewToImage();
  }

  appendSpinner() {
    const preview = document.querySelector("#noshi_download_preview");
    const spinner = document.createElement("div");
    spinner.innerHTML = `
          <div role="status" class="flex align-middle place-content-center justify-center justify-items-center p-4 m-4">
          <svg aria-hidden="true" class="w-8 h-8 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
              <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only"><%= t('loading') %></span>
      </div>`;
    preview.innerHTML = "";
    preview.appendChild(spinner);
  }

  toggleModal() {
    const modalBackdrop = document.querySelector(".modal-backdrop");
    const noshiModal = document.querySelector(".noshi-modal");
    modalBackdrop.classList.toggle("hidden");
    noshiModal.classList.toggle("hidden");
  }

  previewToImage() {
    const preview = document.querySelector(".preview_paper");
    this.togglePreviewClasses(preview);
    this.absolutePositionText(preview);
    // get form data
    const formData = new FormData(document.querySelector("#new_noshi"));
    window.htmlToImage
      .toJpeg(preview, this.option(formData))
      .then((dataUrl) => {
        // Append image to preview area
        const imageArea = document.querySelector("#noshi_download_preview");
        const image = document.createElement("img");
        image.src = dataUrl;
        image.style.cssText = "margin: 2rem auto; width: auto; height: 400px;";
        image.classList.add("rounded", "border", "border-slate-100");
        imageArea.innerHTML = "";
        imageArea.appendChild(image);
        // Download button downloads new image
        const link = document.querySelector(".noshi_download");
        link.download = "noshi.png";
        link.href = dataUrl;
        this.togglePreviewClasses(preview);
      })
      .catch((error) => {
        console.error("Oops, something went wrong!", error);
      });
  }

  togglePreviewClasses(e) {
    // Toggle certain classes for preview so they don't appear when printed
    // find preview_paper
    const classes = [
      "rounded",
      "rounded-t-none",
      "border",
      "border-slate-100",
      "bg-slate-100",
    ];
    classes.forEach((classname) => {
      e.classList.toggle(classname);
    });
  }

  absolutePositionText(preview) {
    // This will be reset when the modal is closed or page is reloaded, so no need to un-toggle
    preview.querySelectorAll(".text_original").forEach((text) => {
      // Find current left position of centered text element relative to .preview_area
      const textPosition = text.getBoundingClientRect();
      const previewPosition = preview.getBoundingClientRect();
      const leftPosition = textPosition.left - previewPosition.left;
      // Set absolute position of text element
      text.style.position = "absolute";
      text.style.left = `${leftPosition}px`;
      // .preview_names .text_original needs to set bottom position based on padding-bottom of .names_container
      // check is text element has class .preview_names
      if (text.classList.contains("preview_names")) {
        // find .names_container
        const namesContainer = preview.querySelector(".names_container");
        // find padding-bottom of .names_container
        const paddingBottom = parseInt(
          window.getComputedStyle(namesContainer).paddingBottom
        );
        // set bottom position of text element
        text.style.bottom = `${paddingBottom}px`;
      }
    });
  }

  option(formData) {
    const [width, height] = this.paperSize(formData);
    const filter = (node) => {
      const exclusionClasses = ["noshi_preview_display_info"];
      return !exclusionClasses.some((classname) =>
        node.classList?.contains(classname)
      );
    };
    return {
      filter: filter,
      pixelRatio: 6,
      style: {
        minHeight: "100%",
        maxWidth: "100%",
        width: "100%",
        height: "100%",
        margin: "0",
        padding: "0",
      },
    };
  }

  paperSize(formData) {
    const paperSize = formData.get("noshi[paper_size]");
    const isA4 = paperSize.includes("A4");
    const isPortrait = paperSize.includes("縦");
    return isA4
      ? isPortrait
        ? [2480, 3508]
        : [2150, 3035]
      : isPortrait
      ? [3508, 2480]
      : [3035, 2150];
  }
}
