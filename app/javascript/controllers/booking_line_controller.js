import { Controller } from "@hotwired/stimulus"

// Manages a single booking line card: line type toggle, booking type toggle, per-line total, submit prep.
// Each line card gets its own instance via data-controller="booking-line".
export default class extends Controller {
  static targets = ["workFields", "dependentFields", "dietFields", "expenseFields", "lineTypeRadio",
                    "timeFields", "projectFields", "timeRadio", "projectRadio",
                    "rate", "hours", "rateProject", "totalHours",
                    "rateDependent", "hoursDependent", "lineTotal"]

  connect() {
    this.toggleLineType()
    this.toggleFields()
  }

  selectedLineType() {
    const checked = this.lineTypeRadioTargets.find(r => r.checked)
    return checked ? checked.value : "work"
  }

  isWorkLine() {
    return this.selectedLineType() === "work"
  }

  // Show a section and (un)disable its fields so hidden inputs aren't posted.
  setSection(target, visible) {
    if (!target) return
    target.style.display = visible ? "" : "none"
    target.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = !visible })
  }

  toggleLineType() {
    const type = this.selectedLineType()
    const isWork = type === "work"

    if (this.hasWorkFieldsTarget) this.setSection(this.workFieldsTarget, isWork)
    if (this.hasDependentFieldsTarget) this.setSection(this.dependentFieldsTarget, !isWork)
    // Type-specific dependent sub-sections (only one applies at a time).
    if (this.hasDietFieldsTarget) this.setSection(this.dietFieldsTarget, type === "diet")
    if (this.hasExpenseFieldsTarget) this.setSection(this.expenseFieldsTarget, type === "expense")

    if (isWork) {
      this.toggleFields()
    }
    this.updateTotal()
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

    if (this.isWorkLine()) {
      if (this.timeBasedSelected()) {
        if (this.hasRateTarget) rate = parseFloat(String(this.rateTarget.value).replace(",", ".")) || 0
        if (this.hasHoursTarget) hours = parseFloat(String(this.hoursTarget.value).replace(",", ".")) || 0
      } else {
        if (this.hasRateProjectTarget) rate = parseFloat(String(this.rateProjectTarget.value).replace(",", ".")) || 0
        if (this.hasTotalHoursTarget) hours = parseFloat(String(this.totalHoursTarget.value).replace(",", ".")) || 0
      }
    } else {
      if (this.hasRateDependentTarget) rate = parseFloat(String(this.rateDependentTarget.value).replace(",", ".")) || 0
      if (this.hasHoursDependentTarget) hours = parseFloat(String(this.hoursDependentTarget.value).replace(",", ".")) || 0
    }

    const total = rate * hours
    if (this.hasLineTotalTarget) {
      this.lineTotalTarget.textContent = "kr " + total.toFixed(2)
    }

    this.dispatch("totalChanged", { detail: { total } })
  }

  enableFields(target) {
    if (target) target.querySelectorAll("input, select, textarea").forEach((el) => { el.disabled = false })
  }

  stripNames(target) {
    if (target) target.querySelectorAll("input, select, textarea").forEach((el) => { if (el.name) el.removeAttribute("name") })
  }

  // Called by the parent form controller before submit: enable all fields,
  // then strip name from inactive section so duplicates aren't posted.
  prepareSubmit() {
    const type = this.selectedLineType()
    const isWork = type === "work"

    // Enable everything first, then strip names from whatever doesn't apply.
    if (this.hasWorkFieldsTarget) this.enableFields(this.workFieldsTarget)
    if (this.hasDependentFieldsTarget) this.enableFields(this.dependentFieldsTarget)
    if (this.hasDietFieldsTarget) this.enableFields(this.dietFieldsTarget)
    if (this.hasExpenseFieldsTarget) this.enableFields(this.expenseFieldsTarget)

    this.stripNames(isWork ? this.dependentFieldsTarget : this.workFieldsTarget)
    // Type-specific dependent sub-sections: keep only the one that applies.
    if (type !== "diet" && this.hasDietFieldsTarget) this.stripNames(this.dietFieldsTarget)
    if (type !== "expense" && this.hasExpenseFieldsTarget) this.stripNames(this.expenseFieldsTarget)

    // For work lines, also handle time/project toggle
    if (isWork) {
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
}
