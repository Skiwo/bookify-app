import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["micBtn", "recordingUI", "timer", "fileInput", "normalUI"]

  connect() {
    this.recording = false
    this.chunks = []
    this.seconds = 0
  }

  disconnect() {
    this.stopRecording()
  }

  async toggle() {
    if (this.recording) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (e) {
      alert("Microphone access denied")
      return
    }

    this.chunks = []
    this.mediaRecorder = new MediaRecorder(this.stream, { mimeType: this.supportedMimeType() })

    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) this.chunks.push(e.data)
    }

    this.mediaRecorder.onstop = () => this.onRecordingDone()

    this.mediaRecorder.start()
    this.recording = true
    this.seconds = 0
    this.updateUI()
    this.timerInterval = setInterval(() => {
      this.seconds++
      if (this.seconds >= 120) this.stopRecording() // max 2 min
      this.updateTimer()
    }, 1000)
  }

  stopRecording() {
    if (!this.recording) return
    this.recording = false
    clearInterval(this.timerInterval)
    this.mediaRecorder?.stop()
    this.stream?.getTracks().forEach((t) => t.stop())
    this.updateUI()
  }

  cancel() {
    this.recording = false
    clearInterval(this.timerInterval)
    this.mediaRecorder?.stop()
    this.stream?.getTracks().forEach((t) => t.stop())
    this.chunks = []
    this.updateUI()
  }

  onRecordingDone() {
    if (this.chunks.length === 0) return

    const blob = new Blob(this.chunks, { type: this.supportedMimeType() })
    const ext = this.supportedMimeType().includes("webm") ? "webm" : "mp4"
    const file = new File([blob], `voice-${Date.now()}.${ext}`, { type: blob.type })

    const dt = new DataTransfer()
    dt.items.add(file)
    this.fileInputTarget.files = dt.files

    // Auto-submit the form
    this.fileInputTarget.closest("form").requestSubmit()
  }

  updateUI() {
    if (this.recording) {
      this.normalUITarget.classList.add("d-none")
      this.recordingUITarget.classList.remove("d-none")
    } else {
      this.normalUITarget.classList.remove("d-none")
      this.recordingUITarget.classList.add("d-none")
    }
  }

  updateTimer() {
    const m = Math.floor(this.seconds / 60)
    const s = this.seconds % 60
    this.timerTarget.textContent = `${m}:${s.toString().padStart(2, "0")}`
  }

  supportedMimeType() {
    if (MediaRecorder.isTypeSupported("audio/webm;codecs=opus")) return "audio/webm;codecs=opus"
    if (MediaRecorder.isTypeSupported("audio/webm")) return "audio/webm"
    if (MediaRecorder.isTypeSupported("audio/mp4")) return "audio/mp4"
    return "audio/ogg"
  }
}
