import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { placeholder: String }

  connect() {
    if (typeof TomSelect === "undefined") {
      console.warn("[multi-select] TomSelect not loaded")
      return
    }
    this.ts = new TomSelect(this.element, {
      plugins: ["remove_button"],
      placeholder: this.placeholderValue || "Select…",
      maxOptions: null,
      hideSelected: true,
      hidePlaceholder: true,
      onItemAdd: function () {
        this.setTextboxValue("")
        this.refreshOptions()
      },
    })
  }

  disconnect() {
    this.ts?.destroy()
  }
}
