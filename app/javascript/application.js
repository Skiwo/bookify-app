import "@hotwired/turbo-rails"
import "controllers"

// Replace browser confirm() with a Bootstrap modal for all data-turbo-confirm attributes.
// Falls back to native confirm() if the modal element isn't in the DOM yet.
import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message) => {
  return new Promise((resolve) => {
    const modal = document.getElementById("turbo-confirm-modal")
    if (!modal) {
      resolve(window.confirm(message))
      return
    }

    modal.querySelector("[data-confirm-message]").textContent = message

    const bsModal = bootstrap.Modal.getOrCreateInstance(modal)
    let confirmed = false

    const onAccept = () => {
      confirmed = true
      bsModal.hide()
    }

    const onHide = () => {
      modal.querySelector("[data-confirm-accept]").removeEventListener("click", onAccept)
      resolve(confirmed)
    }

    modal.querySelector("[data-confirm-accept]").addEventListener("click", onAccept, { once: true })
    modal.addEventListener("hide.bs.modal", onHide, { once: true })

    bsModal.show()
  })
}
