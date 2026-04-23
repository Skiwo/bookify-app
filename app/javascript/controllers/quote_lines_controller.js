import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "total"]

  connect() {
    this.index = this.containerTarget.querySelectorAll(".quote-line").length
    this.updateTotal()
  }

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_IDX/g, this.index++)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(e) {
    const line = e.target.closest(".quote-line")
    if (this.containerTarget.querySelectorAll(".quote-line").length > 1) {
      line.remove()
      this.updateTotal()
    }
  }

  calculate(e) {
    const line = e.target.closest(".quote-line")
    const rate = parseFloat(line.querySelector("[data-field=rate]").value) || 0
    const hours = parseFloat(line.querySelector("[data-field=hours]").value) || 0
    const amount = line.querySelector("[data-field=amount]")
    amount.textContent = (rate * hours) > 0 ? `kr ${(rate * hours).toLocaleString("nb-NO")}` : "—"
    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    this.containerTarget.querySelectorAll(".quote-line").forEach((line) => {
      const rate = parseFloat(line.querySelector("[data-field=rate]")?.value) || 0
      const hours = parseFloat(line.querySelector("[data-field=hours]")?.value) || 0
      total += rate * hours
    })
    this.totalTarget.textContent = total > 0 ? `kr ${total.toLocaleString("nb-NO")}` : "—"
  }
}
