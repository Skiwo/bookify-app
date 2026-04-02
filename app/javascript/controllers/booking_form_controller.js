import { Controller } from "@hotwired/stimulus"

// Manages the booking form: add/remove lines, grand total, submit preparation.
// Individual line behavior is handled by booking-line controllers on each card.
export default class extends Controller {
  static targets = ["lineContainer", "lineTemplate", "lineCard", "grandTotal"]

  connect() {
    this.boundPrepareSubmit = this.prepareSubmit.bind(this)
    this.element.addEventListener("submit", this.boundPrepareSubmit, { capture: true })
    this.updateGrandTotal()
    this.updateRemoveButtons()
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundPrepareSubmit, { capture: true })
  }

  addLine(event) {
    event.preventDefault()
    const template = this.lineTemplateTarget
    const content = template.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.lineContainerTarget.insertAdjacentHTML("beforeend", content)
    this.updateLineNumbers()
    this.updateRemoveButtons()
  }

  removeLine(event) {
    event.preventDefault()
    const card = event.target.closest("[data-booking-form-target='lineCard']")
    if (!card) return

    const destroyField = card.querySelector("input[name*='_destroy']")
    if (destroyField && card.querySelector("input[name*='[id]']")?.value) {
      // Persisted record: mark for destruction and hide
      destroyField.value = "1"
      card.style.display = "none"
      card.querySelectorAll("[required]").forEach((el) => el.removeAttribute("required"))
    } else {
      // New record: remove from DOM
      card.remove()
    }

    this.updateLineNumbers()
    this.updateRemoveButtons()
    this.updateGrandTotal()
  }

  updateGrandTotal() {
    let total = 0
    this.lineCardTargets.forEach((card) => {
      if (card.style.display === "none") return
      const lineCtrl = this.application.getControllerForElementAndIdentifier(card, "booking-line")
      if (lineCtrl && lineCtrl.hasLineTotalTarget) {
        const text = lineCtrl.lineTotalTarget.textContent.replace("kr ", "").replace(",", ".")
        total += parseFloat(text) || 0
      }
    })

    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = "kr " + total.toFixed(2)
    }
  }

  // Called by booking-line:totalChanged events bubbling up
  lineTotalChanged() {
    this.updateGrandTotal()
  }

  updateLineNumbers() {
    let num = 1
    this.lineCardTargets.forEach((card) => {
      if (card.style.display === "none") return
      const label = card.querySelector("[data-line-number]")
      if (label) label.textContent = `Line ${num}`
      const posField = card.querySelector("input[name*='[position]']")
      if (posField) posField.value = num - 1
      num++
    })
  }

  updateRemoveButtons() {
    const visible = this.lineCardTargets.filter((c) => c.style.display !== "none")
    const removeButtons = this.element.querySelectorAll("[data-action*='removeLine']")
    removeButtons.forEach((btn) => {
      const card = btn.closest("[data-booking-form-target='lineCard']")
      if (card && card.style.display !== "none") {
        btn.disabled = visible.length <= 1
      }
    })
  }

  prepareSubmit() {
    this.lineCardTargets.forEach((card) => {
      if (card.style.display === "none") return
      const lineCtrl = this.application.getControllerForElementAndIdentifier(card, "booking-line")
      if (lineCtrl) lineCtrl.prepareSubmit()
    })
  }
}
