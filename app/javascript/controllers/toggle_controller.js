import { Controller } from "@hotwired/stimulus"

// Generic toggle controller for showing/hiding panels.
// Usage:
//   <div data-controller="toggle">
//     <div data-toggle-target="panel">Content</div>
//     <button data-action="click->toggle#toggle">Toggle</button>
//   </div>
export default class extends Controller {
  static targets = ["panel", "overlay"]

  toggle() {
    this.panelTargets.forEach(el => el.classList.toggle("open"))
    this.overlayTargets.forEach(el => el.classList.toggle("open"))
  }
}
