import { Controller } from "@hotwired/stimulus"

// Handles booking type switching (time-based vs project-based) and live total calculation.
// Usage: wrap the form in data-controller="booking-form"
export default class extends Controller {
  static targets = ["timeFields", "projectFields", "timeRadio", "projectRadio",
                    "rate", "hours", "rateProject", "totalHours", "total"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const isTime = this.timeRadioTarget.checked

    this.timeFieldsTarget.style.display = isTime ? "" : "none"
    this.projectFieldsTarget.style.display = isTime ? "none" : ""

    this.timeFieldsTarget.querySelectorAll("input,select").forEach(el => el.disabled = !isTime)
    this.projectFieldsTarget.querySelectorAll("input,select").forEach(el => el.disabled = isTime)

    this.updateTotal()
  }

  updateTotal() {
    let rate, hours

    if (this.timeRadioTarget.checked) {
      rate = parseFloat(this.rateTarget.value) || 0
      hours = parseFloat(this.hoursTarget.value) || 0
    } else {
      rate = parseFloat(this.rateProjectTarget.value) || 0
      hours = parseFloat(this.totalHoursTarget.value) || 0
    }

    this.totalTarget.textContent = "kr " + (rate * hours).toFixed(2)
  }
}
