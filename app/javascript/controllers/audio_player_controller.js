import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playBtn", "progress", "progressBar", "time"]

  connect() {
    this.audio = this.audioTarget
    this.playing = false

    this.audio.addEventListener("loadedmetadata", () => this.updateTime())
    this.audio.addEventListener("timeupdate", () => {
      this.updateProgress()
      this.updateTime()
    })
    this.audio.addEventListener("ended", () => {
      this.playing = false
      this.updateIcon()
      this.progressBarTarget.style.width = "0%"
    })
  }

  togglePlay() {
    if (this.playing) {
      this.audio.pause()
    } else {
      this.audio.play()
    }
    this.playing = !this.playing
    this.updateIcon()
  }

  seek(e) {
    const rect = this.progressTarget.getBoundingClientRect()
    const ratio = (e.clientX - rect.left) / rect.width
    this.audio.currentTime = ratio * this.audio.duration
  }

  updateProgress() {
    if (!this.audio.duration) return
    const pct = (this.audio.currentTime / this.audio.duration) * 100
    this.progressBarTarget.style.width = `${pct}%`
  }

  updateTime() {
    const t = this.playing ? this.audio.currentTime : (this.audio.duration || 0)
    if (isNaN(t) || !isFinite(t)) {
      this.timeTarget.textContent = "0:00"
      return
    }
    const m = Math.floor(t / 60)
    const s = Math.floor(t % 60)
    this.timeTarget.textContent = `${m}:${s.toString().padStart(2, "0")}`
  }

  updateIcon() {
    this.playBtnTarget.className = this.playing ? "bi bi-pause-fill" : "bi bi-play-fill"
  }
}
