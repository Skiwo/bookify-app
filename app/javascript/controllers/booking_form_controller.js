import { Controller } from "@hotwired/stimulus"

// Handles booking type switching (time-based vs project-based) and live total calculation.
// Usage: wrap the form in data-controller="booking-form"
//
// Disabled fields are not submitted. We disable the inactive section so only the active
// branch is editable, then on submit (capture): re-enable all controls, and remove the
// `name` attribute from the inactive section only. That way values are included, but we
// avoid duplicate keys (two rate_nok fields) where the last empty one would win.
export default class extends Controller {
  static targets = ["timeFields", "projectFields", "timeRadio", "projectRadio",
                    "rate", "hours", "rateProject", "totalHours", "total"]

  connect() {
    this.boundPrepareSubmit = this.prepareSubmit.bind(this)
    this.element.addEventListener("submit", this.boundPrepareSubmit, { capture: true })
    this.toggleFields()
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundPrepareSubmit, { capture: true })
  }

  prepareSubmit() {
    const isTime = this.timeBasedSelected()
    const timeControls = this.timeFieldsTarget.querySelectorAll("input, select, textarea")
    const projectControls = this.projectFieldsTarget.querySelectorAll("input, select, textarea")

    timeControls.forEach((el) => { el.disabled = false })
    projectControls.forEach((el) => { el.disabled = false })

    const inactive = isTime ? projectControls : timeControls
    inactive.forEach((el) => {
      if (!el.name) return
      el.dataset.bookingFormSuppressedName = el.name
      el.removeAttribute("name")
    })
  }

  /** True when the checked booking_type radio is time-based (default if none checked). */
  timeBasedSelected() {
    const selected = this.element.querySelector('input[name="booking[booking_type]"]:checked')
    return selected?.value !== "project_based"
  }

  toggleFields() {
    const isTime = this.timeBasedSelected()

    this.timeFieldsTarget.style.display = isTime ? "" : "none"
    this.projectFieldsTarget.style.display = isTime ? "none" : ""

    this.timeFieldsTarget.querySelectorAll("input,select").forEach(el => el.disabled = !isTime)
    this.projectFieldsTarget.querySelectorAll("input,select").forEach(el => el.disabled = isTime)

    this.updateTotal()
  }

  updateTotal() {
    let rate, hours

    if (this.timeBasedSelected()) {
      rate = parseFloat(this.rateTarget.value) || 0
      hours = parseFloat(this.hoursTarget.value) || 0
    } else {
      rate = parseFloat(this.rateProjectTarget.value) || 0
      hours = parseFloat(this.totalHoursTarget.value) || 0
    }

    this.totalTarget.textContent = "kr " + (rate * hours).toFixed(2)
  }
}
