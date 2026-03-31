import { Controller } from "@hotwired/stimulus"

// Auto-submit a form when an input changes.
// Usage:
//   <form data-controller="auto-submit">
//     <input data-action="change->auto-submit#submit">
//   </form>
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
