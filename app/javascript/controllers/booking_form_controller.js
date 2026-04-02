import { Controller } from "@hotwired/stimulus"

// Booking create/edit: one rate (rate_nok), one quantity field whose param name toggles
// between booking[hours] and booking[total_hours]. Inactive section inputs lose `name` so
// they are not submitted (no disabled fields). Form has data-action input->updateTotal.
export default class extends Controller {
  static targets = ["timeSection", "projectSection", "rate", "quantity", "total"]

  connect() {
    this.toggleFields()
  }

  timeBasedSelected() {
    const selected = this.element.querySelector('input[name="booking[booking_type]"]:checked')
    return selected?.value !== "project_based"
  }

  toggleFields() {
    const isTime = this.timeBasedSelected()

    this.timeSectionTarget.classList.toggle("d-none", !isTime)
    this.projectSectionTarget.classList.toggle("d-none", isTime)

    this.quantityTarget.name = isTime ? "booking[hours]" : "booking[total_hours]"

    this.applySection(this.timeSectionTarget, isTime)
    this.applySection(this.projectSectionTarget, !isTime)

    this.updateTotal()
  }

  applySection(section, active) {
    section.querySelectorAll("input, select, textarea").forEach((el) => {
      if (active) {
        const stored = el.getAttribute("data-booking-form-stored-name")
        if (stored) {
          el.name = stored
          el.removeAttribute("data-booking-form-stored-name")
        }
      } else if (el.name) {
        el.setAttribute("data-booking-form-stored-name", el.name)
        el.removeAttribute("name")
      }
    })
  }

  updateTotal() {
    const rate = this.parseNum(this.rateTarget.value)
    const qty = this.parseNum(this.quantityTarget.value)
    this.totalTarget.textContent = "kr " + (rate * qty).toFixed(2)
  }

  parseNum(raw) {
    if (raw == null || raw === "") return 0
    const normalized = String(raw).trim().replace(",", ".")
    const n = parseFloat(normalized)
    return Number.isFinite(n) ? n : 0
  }
}
