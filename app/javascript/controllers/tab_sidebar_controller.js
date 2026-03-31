import { Controller } from "@hotwired/stimulus"

// Show/hide sidebar panels based on Bootstrap tab activation.
// Usage:
//   <div data-controller="tab-sidebar">
//     <button data-action="shown.bs.tab->tab-sidebar#switch"
//             data-tab-sidebar-show-param="sandbox">Sandbox</button>
//     <div data-tab-sidebar-target="panel" data-tab-sidebar-name="sandbox">...</div>
//     <div data-tab-sidebar-target="panel" data-tab-sidebar-name="production">...</div>
//   </div>
export default class extends Controller {
  static targets = ["panel"]

  switch(event) {
    const name = event.params.show
    this.panelTargets.forEach(panel => {
      panel.style.display = panel.dataset.tabSidebarName === name ? "" : "none"
    })
  }
}
