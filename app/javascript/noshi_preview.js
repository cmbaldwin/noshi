"use strict";

export default class NoshiPreview {
  _noshi_form = document.querySelector(".noshi_form");
  _user_id = document.querySelector("#user_id")?.value;
  _formatRadios = document.querySelectorAll(".format_select");
  _noshiDesignList = document.getElementById("noshi_design_list");
  _noshiTypeField = document.querySelector("#noshi_ntype");
  _fontSizeSelect = document.querySelector(".font_size");
  _ometegakiSelect = document.querySelector(".omotegaki_select");
  _ometegakiBtns = document.querySelectorAll(".omotegaki_btn");
  _omotegakiInput = document.querySelector("#noshi_omotegaki");
  _ometegakiSizeSelect = document.querySelector(".omotegaki_size_select");
  _nameInputs = document.querySelectorAll(".name_input");
  _previewArea = document.querySelector(".preview_area");
  _omotegakiPosUpBtn = document.querySelector(".omotegaki-up");
  _omotegakiPosDownBtn = document.querySelector(".omotegaki-down");
  _namesPosUpBtn = document.querySelector(".names-up");
  _namesPosDownBtn = document.querySelector(".names-down");
  _submitBtn = document.querySelector("#noshi_submit");
  _modalCloseBtn = document.querySelector(".close_modal");
  _b5WidthPx = 3035; // px@300dpi
  _b5HeightPx = 2150;
  _a4WidthPx = 3508;
  _a4HeightPx = 2480;

  constructor() {
    if (!this._noshi_form) return;

    this._paperSize = document.querySelector(".noshi_form input:checked").value;
    this._nType = this._noshiTypeField.value;
    this._nTypeUrl =
      this._noshiDesignList.querySelectorAll(".noshi")[0].dataset.fullNoshiUrl;
    this._ometegaki = this._omotegakiInput.value;
    this._ometegakiSizePt = this._paperSize == "A4" ? 156 : 132; // 36px for two characters * 0.75 for px -> pt
    this._ometegakiOffset;
    this._ometegakiPreviewMargin;
    this._omotegakiTopMarginFull; // (default b5: 2079px) * 22.5%(est from top) * 0.75 for px -> pt
    this._omotegakiTMargin;
    this._names = Array.from(this._nameInputs)
      .map((inp) => inp.value)
      .filter((name) => name);
    this._namesPreviewMargin;
    this._namesOffset;
    this._fontSize = this._fontSizeSelect.value;
    this._namesBMargin;
    this._namesBMarginFull;
    this._namesTMargin;
    this._namesTMarginFull;

    this._setFormat();
    this._formatRadios.forEach((radio) => {
      radio.addEventListener("change", () => {
        this._setFormat();
        this.updatePreview();
      });
    });
    this._noshiDesignList.addEventListener(
      "click",
      this._noshiListListener.bind(this)
    );
    this._fontSizeSelect.addEventListener(
      "change",
      this._fontSizeListener.bind(this)
    );
    this._ometegakiSelect.addEventListener(
      "change",
      this._ometegakiSelectListener.bind(this)
    );
    this._ometegakiBtns.forEach((btn) => {
      btn.addEventListener("click", this._ometegakiBtnListener.bind(this));
    });
    this._omotegakiInput.addEventListener(
      "input",
      this._ometegakiInputListener.bind(this)
    );
    this._ometegakiSizeSelect.addEventListener(
      "change",
      this._ometegakiSizeListener.bind(this)
    );
    this._nameInputs.forEach((input) => {
      input.addEventListener("input", this._nameInputListener.bind(this));
    });
    [
      this._omotegakiPosUpBtn,
      this._omotegakiPosDownBtn,
      this._namesPosUpBtn,
      this._namesPosDownBtn,
    ].forEach((btn) => {
      btn.addEventListener("click", this._posBtnListener.bind(this));
    });
    // Create and save button
    // this._submitBtn.addEventListener("click", this._submitBtnListener.bind(this));
    this._updatePreview = this.updatePreview.bind(this);
    window.addEventListener("resize", this.onResize.bind(this));
    this._modalCloseBtn.addEventListener("click", this._updatePreview);
    this.updatePreview();
  }

  // // currently disabled
  // _submitBtnListener(e) {
  //     e.preventDefault();
  //     this._submitBtn.disabled = true;
  //     this._submitBtn.style.backgroundColor = '#ccc';
  //     this._submitBtn.textContent = `${this._submitBtn.dataset.processing}`;
  //     this._noshi_form.submit();
  // }

  onResize() {
    this._updatePreview();
  }

  _posBtnListener(e) {
    const classListStr = Array.from(e.target.closest("span").classList).join(
      ""
    );
    const isOmotegaki = classListStr.includes("omotegaki");
    const isUp = classListStr.includes("up");
    this._moveEl(isOmotegaki, isUp);
    this.updatePreview();
  }

  _moveEl(isOmotegaki, isUp) {
    // padding top for omotegaki, padding bottom for names
    if (isOmotegaki) {
      if (isUp) {
        this._ometegakiTMargin -= 1;
      } else {
        this._ometegakiTMargin += 1;
      }
    } else {
      if (isUp) {
        this._namesBMargin += 1;
      } else {
        this._namesBMargin -= 1;
      }
    }
  }

  _noshiListListener(e) {
    e.preventDefault();
    const selected = e.target.closest("div.noshi");
    if (selected) {
      this._setActiveNType(selected);
      this.updatePreview();
    }
  }

  _getDocHeight() {
    return this._paperSize == "A4" ? this._a4HeightPx : this._b5HeightPx;
  }

  _fontSizeListener(e) {
    this._fontSize = e.target.value;
    this.updatePreview();
  }

  _ometegakiSelectListener(e) {
    e.preventDefault();
    this._omotegakiInput.value = e.target.value;
    this._ometegaki = e.target.value;
    this.updatePreview();
  }

  _ometegakiBtnListener(e) {
    e.preventDefault();
    this._omotegakiInput.value = e.target.textContent;
    this._ometegaki = e.target.textContent;
    this.updatePreview();
  }

  _ometegakiInputListener(e) {
    this._ometegaki = e.target.value;
    this.updatePreview();
  }

  _setOmetegakiSize() {
    // calc top offest in pixels
    // Note: there is about 16 characters good space (for two characters at 27pt/36px) between top and bottom of document
    // characters over 2, multiply by their size in px and adjust with  the diff multiplier
    const charOffset = this._ometegaki.length * this._ometegakiSizePt;
    let ometegakiOffsetPx =
      (this._getDocHeight() * 0.12 - charOffset) * this._diffMultiplier(); // 12% from top est placement
    if (ometegakiOffsetPx < 0) {
      ometegakiOffsetPx = 0;
    }
    // set the offset to full 300dpi px
    this._ometegakiTMargin ??= parseInt(ometegakiOffsetPx);
    this._omotegakiTopMarginFull =
      this._ometegakiTMargin * this._diffMultiplier(); // 0.75 for px -> pt
  }

  _ometegakiSizeListener(e) {
    this._ometegakiSizePt = e.target.value;
    this.updatePreview();
  }

  _nameInputListener(e) {
    this._names = [];
    this._nameInputs.forEach((input) => {
      if (input.value.length > 0) {
        this._names.push(input.value);
      }
    });
    this.updatePreview();
  }

  _setActiveNType(selected) {
    const designNum = Number.parseInt(selected.dataset.noshiId) + 1;
    const noshiInputField = document.querySelector("#noshi_ntype");
    this._noshiDesignList.querySelectorAll("div.noshi").forEach((a) => {
      a.classList.remove("bg-sky-500");
    });
    selected.classList.add("bg-sky-500");
    // Set state value
    this._nType = designNum;
    this._nTypeUrl = selected.dataset.fullNoshiUrl;
    // Set form value
    noshiInputField.value = designNum;
  }

  _setFormat() {
    this._formatRadios.forEach((radio) => {
      if (radio.checked) {
        // Set state variable
        let selected;
        const prevVal = this._paperSize;
        this._paperSize = radio.value;
        // Hide all
        this._noshiDesignList.querySelectorAll("div.noshi").forEach((a) => {
          a.classList.add("hidden");
        });
        // Show only applicable options, and select one
        if (radio.value.includes("縦")) {
          this._noshiDesignList
            .querySelectorAll(".portrait-noshi")
            .forEach((a) => {
              a.classList.remove("hidden");
            });
          if (!prevVal.includes("縦")) {
            selected = this._noshiDesignList.querySelector(".portrait-noshi");
            this._setActiveNType(selected);
          }
        } else {
          this._noshiDesignList
            .querySelectorAll(".landscape-noshi")
            .forEach((a) => {
              a.classList.remove("hidden");
            });
          if (prevVal.includes("縦")) {
            selected = this._noshiDesignList.querySelector(".landscape-noshi");
            this._setActiveNType(selected);
          }
        }
      }
    });
  }

  // Getting to and from the preview size to 300dpi size
  _diffMultiplier() {
    const prevHeight = this._getPrevHeight();
    // For tall noshi
    if (this._paperSize.includes("縦"))
      return this._paperSize === "縦A4"
        ? prevHeight / this._a4WidthPx
        : prevHeight / this._b5WidthPx;
    // Regular landscape style
    return this._paperSize === "A4"
      ? prevHeight / this._a4HeightPx
      : prevHeight / this._b5HeightPx;
  }

  _getAspectRatio() {
    const b5Aspect = "182 / 257"; // JIS https://www.papersizes.org/japanese-sizes.htm in mm
    const b5PAspect = "257 / 182"; // JIS https://www.papersizes.org/japanese-sizes.htm in mm
    const a4Aspect = "210 / 297"; //
    const a4PAspect = "297 / 210"; //
    // For tall/portrait noshi
    if (this._paperSize.includes("縦"))
      return this._paperSize === "縦A4" ? a4PAspect : b5PAspect;
    // Regular landscape style
    return this._paperSize === "A4" ? a4Aspect : b5Aspect;
  }

  _getPrevWidth() {
    return this._paperSize.includes("縦") ? 400 : this._previewArea.offsetWidth;
  }

  _getPrevHeight() {
    return parseInt(eval(this._getAspectRatio()) * this._getPrevWidth());
  }

  _getOmotegakiPreviewFontSize() {
    return (this._ometegakiSizePt / 0.75) * this._diffMultiplier(); // 0.75 for px -> pt, then from 300dpi to preview area
  }

  _setOmotegakiReferences() {
    const omotegakiInputVal = document.querySelector(
      "#noshi_omotegaki_margin_top"
    );
    // Set local reference
    this._omotegakiTopMarginFull =
      this._ometegakiTMargin / this._diffMultiplier(); // from preview to 300dpi px
    // Set form values
    omotegakiInputVal.value =
      parseInt(this._omotegakiTopMarginFull * 100) / 100; // Round to 2 decimal places
  }

  _getOmotegakiOffset() {
    this._setOmotegakiReferences();
    return this._ometegakiTMargin;
  }

  _setNameTMargin() {
    const previewAreaHeight = this._previewArea.offsetHeight;
    const nameAreaHeight =
      document.querySelector(".preview_names").offsetHeight;
    const nameContainerPadding = parseInt(
      document.querySelector(".names_container").style.paddingBottom
    );
    const namesTMInputVal = document.querySelector("#noshi_names_margin_top");
    this._namesTMargin =
      previewAreaHeight - nameAreaHeight - nameContainerPadding; // Reverse diff multiplier
    this._namesTMarginFull = this._namesTMargin / this._diffMultiplier(); // from preview to 300 dpi
    namesTMInputVal.value = parseInt(this._namesTMarginFull * 100) / 100; // Round to 2 decimal places
  }
  _setNameReferences() {
    const namesBMInputVal = document.querySelector(
      "#noshi_names_margin_bottom"
    );
    // Set local reference
    this._namesBMarginFull = this._namesBMargin / this._diffMultiplier(); // get from preview to 300dpi
    // Set form values
    namesBMInputVal.value = parseInt(this._namesBMarginFull * 100) / 100; // Round to 2 decimal places
  }

  _getNamesOffset() {
    this._namesBMargin ??= parseInt(
      this._getPrevHeight() * 0.25 -
        this._names.length * this._getPreviewFontSize()
    ); // 25% from bottom est first placement
    this._setNameReferences();
    return this._namesBMargin;
  }

  _getPreview() {
    // ImageMagick uses points for font sizing, will need this later for scaling
    // 1pt = 1/72th of 1in, 1px = 1/96th of 1in, https://pixelsconverter.com/pt-to-px
    const nType = parseInt(this._nType) ? parseInt(this._nType) : 1;
    const bgURL = encodeURI(this._nTypeUrl);
    // set width to 100% if landscape, otherwise user fractional width
    const landscapeWidth = this._paperSize.includes("縦")
      ? " mx-auto w-full"
      : " w-full";
    const portraitWidth = this._paperSize.includes("縦")
      ? "max-width: 400px; "
      : "";
    const namesWidthClass = this._paperSize.includes("縦") ? "" : "";
    const namesWidthStyle = this._paperSize.includes("縦")
      ? "width: 33%; "
      : "width: 25%; ";
    return `
      <div class="rounded rounded-t-none border border-slate-100 bg-slate-100 preview_paper${landscapeWidth}" style="${portraitWidth}height: ${this._getPrevHeight()}px; aspect-ratio: ${this._getAspectRatio()}; background-image: url('${bgURL}'); position: relative; background-origin: border-box; background-repeat: no-repeat; background-position: center; background-size: cover;">
        <div class="preview_omotegaki text_original" style="margin: 0 auto; font-size: ${this._getOmotegakiPreviewFontSize()}px; padding-top: ${this._getOmotegakiOffset()}px; font-family: serif; writing-mode: vertical-rl; text-orientation: upright;">
          <span class="preview_omotegaki_span cursor-ns-resize select-none takao-pmincho" style="z-index: 10">${
            this._ometegaki
          }</span>
        </div>
        <div class="container-flex w-full names_container" style="padding-bottom: ${this._getNamesOffset()}px; position: absolute; bottom: 0px;">
          <div class="preview_names text_original flex cursor-ns-resize select-none ${namesWidthClass}" style="margin: 0 auto; align-content: center; justify-content: center; ${namesWidthStyle}">
            ${this._getNames()}
          </div>
        </div>
        ${this._getDisplayInfo()}
      </div>
    `;
  }

  _getPreviewFontSize() {
    return parseInt((this._fontSize / 0.75) * this._diffMultiplier()); // 0.75 for px -> pt
  }

  _getNames() {
    return this._names
      .reverse()
      .map((name, _i) => {
        return `
        <div class="preview_name col-2 px-0 takao-pmincho" style="font-size: ${this._getPreviewFontSize()}px; font-family: serif; writing-mode: vertical-rl; text-orientation: upright; display:flex; align-items:center; line-height: 1.1em;">
          ${name}
        </div>
      `;
      })
      .join("");
  }

  _getDisplayInfo() {
    const paperPx =
      this._paperSize === "A4"
        ? `${this._a4WidthPx}x${this._a4HeightPx}`
        : `${this._b5WidthPx}x${this._b5HeightPx}`;
    return `
      <div class="noshi_preview_display_info rounded opacity-25" style="display: block; position: absolute; bottom: 3px; right: 3px; font-size: 9px;">
        ${this._paperSize.toUpperCase()}(${this._getAspectRatio().replace(
      " / ",
      "pt x "
    )}pt:): ${this._getPrevWidth()}px x ${this._getPrevHeight()}px /${
      Math.round(this._diffMultiplier() * 100) / 100
    } -> (${paperPx})
      </div>
    `;
  }

  _renderShadowing() {
    const portrait_gravitys = [0.1707, 0.8374];
    const previewPaper = document.querySelector(".preview_paper");
    // Omotegaki cloning
    const omotegakiNode = document.querySelector(".preview_omotegaki");
    const omotegakiClone = omotegakiNode.cloneNode(true);
    omotegakiClone.style.position = "absolute";
    omotegakiClone.classList.add("omotegaki_shadow", "takao-pmincho");
    omotegakiClone.classList.remove("text_original");
    omotegakiClone.style.zIndex = "9";
    omotegakiClone.style.left =
      previewPaper.offsetWidth * portrait_gravitys[0] -
      omotegakiNode.offsetWidth / 2 +
      "px";
    const shadowSpan = omotegakiClone.querySelector("span");
    shadowSpan.style.zIndex = "9";
    shadowSpan.classList.value = "cursor-default user-select-none";
    previewPaper.insertAdjacentHTML("afterbegin", omotegakiClone.outerHTML);
    omotegakiClone.style.left =
      previewPaper.offsetWidth * portrait_gravitys[1] -
      omotegakiNode.offsetWidth / 2 +
      "px";
    previewPaper.insertAdjacentHTML("afterbegin", omotegakiClone.outerHTML);
    // Names cloning
    const namesContainer = document.querySelector(".names_container");
    const namesNode = document.querySelector(".preview_names");
    const namesClone = namesNode.cloneNode(true);
    const namesPaddingBottom = parseInt(namesContainer.style.paddingBottom);
    namesClone.classList.remove(
      "text_original",
      "preview_names",
      "hover-border",
      "mx-auto",
      "cursor-ns-resize"
    );
    namesClone.classList.add("takao-pmincho", "names_shadow", "cursor-default");
    namesClone.style.position = "absolute";
    namesClone.style.paddingBottom = `${namesPaddingBottom}px`;
    namesClone.style.zIndex = "9";
    namesClone.style.left = "0px";
    namesClone.style.marginLeft = "0px";
    namesClone.style.bottom = "3px";
    previewPaper.insertAdjacentHTML("afterbegin", namesClone.outerHTML);
    namesClone.style.left = "";
    namesClone.style.marginRight = "0px";
    namesClone.style.right = "0px";
    previewPaper.insertAdjacentHTML("beforeend", namesClone.outerHTML);
  }

  _dragListener() {
    const omotegakiEl = document.querySelector(".preview_omotegaki_span");
    const namesEl = document.querySelector(".preview_names");
    const previewAreaBounds = this._previewArea.getBoundingClientRect();

    function touchHandler(event) {
      var touch = event.changedTouches[0];
      var simulatedEvent = new MouseEvent(
        {
          touchstart: "mousedown",
          touchmove: "mousemove",
          touchend: "mouseup",
        }[event.type],
        true,
        true,
        window,
        1,
        touch.screenX,
        touch.screenY,
        touch.clientX,
        touch.clientY,
        false,
        false,
        false,
        false,
        0,
        null
      );
      touch.target.dispatchEvent(simulatedEvent);
    }

    document.addEventListener("touchstart", touchHandler, true);
    document.addEventListener("touchmove", touchHandler, true);
    document.addEventListener("touchend", touchHandler, true);
    document.addEventListener("touchcancel", touchHandler, true);

    [omotegakiEl, namesEl].forEach((el) => {
      const parentElement = el.parentElement;

      el.addEventListener("mousedown", (e) => {
        const initMouseY = e.clientY;
        const elBounds = el.getBoundingClientRect();
        const move = (ev) => {
          const diff = ev.clientY - initMouseY;
          let margin;
          if (el === omotegakiEl) {
            margin = previewAreaBounds.top - elBounds.top + 1; // 1 for border
            this._ometegakiTMargin = Math.abs(margin) + diff;
            this._setOmotegakiReferences();
            parentElement.style.paddingTop = `${this._ometegakiTMargin}px`;
          } else {
            margin = previewAreaBounds.bottom - elBounds.bottom - 1; // 1 for border
            this._namesBMargin = margin - diff;
            this._setNameReferences();
            parentElement.style.paddingBottom = `${this._namesBMargin}px`;
            this._setNameTMargin();
          }
          if (this._paperSize.includes("縦")) {
            ["names_shadow", "omotegaki_shadow"].forEach((els) => {
              document.querySelectorAll(`.${els}`).forEach((el) => el.remove());
            });
            this._renderShadowing();
          }
        };

        const remove = () => {
          document.removeEventListener("mousemove", move);
          document.removeEventListener("mouseup", remove);
        };

        document.addEventListener("mousemove", move);
        document.addEventListener("mouseup", remove);
      });
    });
  }

  updatePreview() {
    this._setOmetegakiSize();

    // In the case the PreviewNoshi class firing before the modal is finished rendering, leave the 'it'll render here' text.
    if (this._getPrevHeight() > 0) {
      const newMarkup = this._getPreview();

      // If adding fresh noshi or new nodes, refresh all. Else, replace text and attributes of existing DOM nodes only.
      if (this._previewArea.textContent.includes("選択")) {
        this._previewArea.innerHTML = this._getPreview();
      } else {
        const newDOM = document
          .createRange()
          .createContextualFragment(newMarkup);
        const newElements = Array.from(newDOM.querySelectorAll("*"));
        const curElements = Array.from(this._previewArea.querySelectorAll("*"));
        // In the case new elements are added (like for switching from landscape to portrait)
        // we need to replace the entire preview area.
        if (newElements.length !== curElements.length) {
          this._previewArea.innerHTML = this._getPreview();
        } else {
          newElements.forEach((newEl, i) => {
            const curEl = curElements[i];

            // Updates changed TEXT
            if (
              !newEl.isEqualNode(curEl) &&
              newEl.firstChild?.nodeValue.trim() !== ""
            ) {
              curEl.textContent = newEl.textContent;
            }

            // Updates changed ATTRIBUES
            if (!newEl.isEqualNode(curEl))
              Array.from(newEl.attributes).forEach((attr) =>
                curEl.setAttribute(attr.name, attr.value)
              );
          });
        }
      }

      // Shadowing for portrait mode
      if (this._paperSize.includes("縦")) this._renderShadowing();

      // Add listeners for positioning text by dragging
      this._dragListener();

      // Set names top margin after rendering (needs DOM to be rendered)
      this._setNameTMargin();
    }

    // Debugging
    console.log(this);
  }
}
