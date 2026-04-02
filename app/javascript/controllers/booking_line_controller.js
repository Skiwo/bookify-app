import { Controller } from "@hotwired/stimulus"

// Manages a single booking line card: type toggle, per-line total, submit prep.
// Each line card gets its own instance via data-controller="booking-line".
export default class extends Controller {
  static targets = ["timeFields", "projectFields", "timeRadio", "projectRadio",
                    "rate", "hours", "rateProject", "totalHours", "lineTotal"]

  connect() {
    this.toggleFields()
  }

  timeBasedSelected() {
    if (!this.hasTimeRadioTarget) return true
    return this.timeRadioTarget.checked
  }

  toggleFields() {
    const isTime = this.timeBasedSelected()

    if (this.hasTimeFieldsTarget) {
      this.timeFieldsTarget.style.display = isTime ? "" : "none"
      this.timeFieldsTarget.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = !isTime })
    }
    if (this.hasProjectFieldsTarget) {
      this.projectFieldsTarget.style.display = isTime ? "none" : ""
      this.projectFieldsTarget.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = isTime })
    }

    this.updateTotal()
  }

  updateTotal() {
    let rate = 0
    let hours = 0

    if (this.timeBasedSelected()) {
      if (this.hasRateTarget) rate = parseFloat(String(this.rateTarget.value).replace(",", ".")) || 0
      if (this.hasHoursTarget) hours = parseFloat(String(this.hoursTarget.value).replace(",", ".")) || 0
    } else {
      if (this.hasRateProjectTarget) rate = parseFloat(String(this.rateProjectTarget.value).replace(",", ".")) || 0
      if (this.hasTotalHoursTarget) hours = parseFloat(String(this.totalHoursTarget.value).replace(",", ".")) || 0
    }

    const total = rate * hours
    if (this.hasLineTotalTarget) {
      this.lineTotalTarget.textContent = "kr " + total.toFixed(2)
    }

    this.dispatch("totalChanged", { detail: { total } })
  }

  // Called by the parent form controller before submit: enable all fields,
  // then strip name from inactive section so duplicates aren't posted.
  prepareSubmit() {
    const isTime = this.timeBasedSelected()

    if (this.hasTimeFieldsTarget) {
      this.timeFieldsTarget.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = false })
    }
    if (this.hasProjectFieldsTarget) {
      this.projectFieldsTarget.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = false })
    }

    const inactive = isTime ? this.projectFieldsTarget : this.timeFieldsTarget
    if (inactive) {
      inactive.querySelectorAll("input, select, textarea").forEach((el) => {
        if (el.name) el.removeAttribute("name")
      })
    }
  }
}
