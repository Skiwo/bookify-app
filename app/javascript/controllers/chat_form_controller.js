import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  reset() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    requestAnimationFrame(() => {
      const msgs = document.querySelector("#chat-messages")
      const last = msgs?.lastElementChild
      if (last) last.scrollIntoView({ block: "end" })
    })
  }
}
