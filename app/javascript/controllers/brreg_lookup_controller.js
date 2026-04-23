import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["orgNumber", "name", "address", "status"]

  connect() {
    this._timer = null
  }

  fetch() {
    const raw = this.orgNumberTarget.value.replace(/\D/g, "")
    clearTimeout(this._timer)

    if (raw.length !== 9) {
      this._setStatus("", "")
      return
    }

    this._setStatus("Søker i BRREG…", "text-muted")
    this._timer = setTimeout(() => this._lookup(raw), 400)
  }

  async _lookup(orgNumber) {
    try {
      const res = await fetch(`/clients/brreg_lookup?org_number=${orgNumber}`, {
        headers: { Accept: "application/json" }
      })
      const data = await res.json()

      if (res.ok) {
        this.nameTarget.value = data.name || ""
        this.addressTarget.value = data.address || ""
        this._setStatus("✓ Funnet i BRREG", "text-success")
      } else {
        this.nameTarget.value = ""
        this.addressTarget.value = ""
        this._setStatus(data.error, "text-danger")
      }
    } catch {
      this._setStatus("BRREG-oppslag feilet", "text-danger")
    }
  }

  _setStatus(text, cssClass) {
    this.statusTarget.textContent = text
    this.statusTarget.className = `form-text ${cssClass}`
  }
}
