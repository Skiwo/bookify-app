import { Controller } from "@hotwired/stimulus"

// Time-based vs project-based sections: inactive block uses disabled inputs (not submitted).
// On submit (capture): enable all, then strip `name` from inactive section only so duplicate
// rate_nok and wrong branch params are not posted.
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
      el.removeAttribute("name")
    })
  }

  timeBasedSelected() {
    const selected = this.element.querySelector('input[name="booking[booking_type]"]:checked')
    return selected?.value !== "project_based"
  }

  toggleFields() {
    const isTime = this.timeBasedSelected()

    this.timeFieldsTarget.style.display = isTime ? "" : "none"
    this.projectFieldsTarget.style.display = isTime ? "none" : ""

    this.timeFieldsTarget.querySelectorAll("input,select").forEach((el) => { el.disabled = !isTime })
    this.projectFieldsTarget.querySelectorAll("input,select").forEach((el) => { el.disabled = isTime })

    this.updateTotal()
  }

  updateTotal() {
    let rate
    let hours

    if (this.timeBasedSelected()) {
      rate = parseFloat(String(this.rateTarget.value).replace(",", ".")) || 0
      hours = parseFloat(String(this.hoursTarget.value).replace(",", ".")) || 0
    } else {
      rate = parseFloat(String(this.rateProjectTarget.value).replace(",", ".")) || 0
      hours = parseFloat(String(this.totalHoursTarget.value).replace(",", ".")) || 0
    }

    this.totalTarget.textContent = "kr " + (rate * hours).toFixed(2)
  }
}
