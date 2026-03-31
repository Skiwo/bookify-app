import { Controller } from "@hotwired/stimulus"

// Copy text to clipboard with visual feedback.
// Usage:
//   <div data-controller="clipboard">
//     <input data-clipboard-target="source" value="text to copy" readonly>
//     <button data-action="click->clipboard#copy">Copy</button>
//   </div>
export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
    const button = this.element.querySelector("[data-action*='clipboard#copy']")
    const original = button.textContent
    button.textContent = "Copied!"
    setTimeout(() => button.textContent = original, 2000)
  }
}
