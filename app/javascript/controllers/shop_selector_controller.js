import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "bar", "count", "slugContainer", "submitBtn", "limitNotice"]
  static values = { max: { type: Number, default: 5 } }

  connect() {
    this._update()
  }

  toggle() {
    const checked = this._checked()

    // Enforce max — uncheck extras
    if (checked.length > this.maxValue) {
      // find the last checked one and uncheck it
      const overflow = checked[checked.length - 1]
      overflow.checked = false
    }

    this._update()
  }

  _checked() {
    return this.checkboxTargets.filter(cb => cb.checked)
  }

  _update() {
    const selected = this._checked()
    const count = selected.length
    const atMax = count >= this.maxValue

    this.countTargets.forEach(el => { el.textContent = count })

    if (this.hasBarTarget) {
      this.barTarget.classList.toggle("d-none", count === 0)
    }

    if (this.hasLimitNoticeTarget) {
      this.limitNoticeTarget.classList.toggle("d-none", !atMax)
    }

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.value = count === 1
        ? "Send request to 1 shop"
        : `Send request to ${count} shops`
    }

    // Disable unchecked boxes when at max
    this.checkboxTargets.forEach(cb => {
      if (!cb.checked) cb.disabled = atMax
    })

    // Sync hidden slug inputs into the form
    if (this.hasSlugContainerTarget) {
      this.slugContainerTarget.innerHTML = ""
      selected.forEach(cb => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = "shop_slugs[]"
        input.value = cb.dataset.slug
        this.slugContainerTarget.appendChild(input)
      })
    }
  }
}
