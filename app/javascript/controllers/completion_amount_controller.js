import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hours", "total"]
  static values = { rate: Number, commission: Number }

  recalc() {
    const hours = parseFloat(this.hoursTarget.value) || 0
    const work_ore = this.rateValue * hours
    const total_ore = work_ore * (1 + this.commissionValue / 100) * 1.25
    const total_nok = Math.round(total_ore / 100)
    this.totalTarget.textContent = `kr ${total_nok.toLocaleString("nb-NO")}`
  }
}
