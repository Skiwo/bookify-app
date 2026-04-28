import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "item", "destroy", "empty"]

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this._updateEmpty()
  }

  remove(e) {
    const item = e.target.closest("[data-nested-form-target='item']")
    const destroyInput = item.querySelector("[data-nested-form-target='destroy']")

    if (destroyInput) {
      destroyInput.value = "1"
      item.style.display = "none"
    } else {
      item.remove()
    }
    this._updateEmpty()
  }

  _updateEmpty() {
    if (!this.hasEmptyTarget) return
    const visible = this.itemTargets.filter(i => i.style.display !== "none")
    this.emptyTarget.style.display = visible.length === 0 ? "" : "none"
  }
}
