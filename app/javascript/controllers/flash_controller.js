import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._timer = setTimeout(() => this._dismiss(), 4000)
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    this._dismiss()
  }

  _dismiss() {
    this.element.classList.remove("show")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
