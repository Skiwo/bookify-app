import { Controller } from "@hotwired/stimulus"

// New booking form: syncs quantity param name, strips inactive section field names, live total.
export default class extends Controller {
  static targets = ["total"]

  connect() {
    this.onInput = () => this.refresh()
    this.onSubmit = () => this.syncMode()
    this.element.addEventListener("input", this.onInput)
    this.element.addEventListener("submit", this.onSubmit, { capture: true })
    this.syncMode()
    this.refresh()
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
    this.element.removeEventListener("submit", this.onSubmit, { capture: true })
  }

  modeChanged() {
    this.syncMode()
    this.refresh()
  }

  syncMode() {
    const sel = this.element.querySelector('select[name="booking[booking_type]"]')
    const project = sel && sel.value === "project_based"

    const timeBlock = this.element.querySelector("#js-booking-time-block")
    const projBlock = this.element.querySelector("#js-booking-project-block")
    const qty = this.element.querySelector("#js-booking-quantity")

    if (timeBlock) {
      timeBlock.hidden = project
      this.applyNames(timeBlock, project)
    }
    if (projBlock) {
      projBlock.hidden = !project
      this.applyNames(projBlock, !project)
    }
    if (qty) qty.name = project ? "booking[total_hours]" : "booking[hours]"
  }

  /** If strip is true, remove name from fields (inactive block). If false, restore from data-was-name. */
  applyNames(block, strip) {
    block.querySelectorAll("input, select, textarea").forEach((el) => {
      if (strip) {
        if (el.name) {
          el.setAttribute("data-was-name", el.name)
          el.removeAttribute("name")
        }
      } else {
        const prev = el.getAttribute("data-was-name")
        if (prev) {
          el.name = prev
          el.removeAttribute("data-was-name")
        }
      }
    })
  }

  refresh() {
    const rateEl = this.element.querySelector('input[name="rate_nok"]')
    const qtyEl = this.element.querySelector("#js-booking-quantity")
    const r = this.parseNum(rateEl && rateEl.value)
    const q = this.parseNum(qtyEl && qtyEl.value)
    if (this.hasTotalTarget) this.totalTarget.textContent = "kr " + (r * q).toFixed(2)
  }

  parseNum(v) {
    if (v == null || String(v).trim() === "") return 0
    const n = parseFloat(String(v).replace(",", "."))
    return Number.isFinite(n) ? n : 0
  }
}
