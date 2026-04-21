import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  update() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.innerHTML = `<img src="${e.target.result}" class="rounded-circle" style="width:80px;height:80px;object-fit:cover">`
    }
    reader.readAsDataURL(file)
  }
}
