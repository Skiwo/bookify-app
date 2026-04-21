import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileInput", "filePreview", "fileName"]

  pickFile() {
    this.fileInputTarget.click()
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    if (file.size > 5 * 1024 * 1024) {
      alert("File must be under 5 MB")
      this.clearFile()
      return
    }

    this.fileNameTarget.textContent = file.name
    this.filePreviewTarget.classList.remove("d-none")
  }

  clearFile() {
    this.fileInputTarget.value = ""
    if (this.hasFilePreviewTarget) {
      this.filePreviewTarget.classList.add("d-none")
      this.fileNameTarget.textContent = ""
    }
  }

  reset() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.clearFile()
    requestAnimationFrame(() => {
      const container = document.querySelector('[data-controller="job-chat"]')
      if (container) container.scrollTop = container.scrollHeight
    })
  }
}
