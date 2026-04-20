import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { jobId: String, userId: String, readUrl: String }

  connect() {
    this.messagesEl = this.element.querySelector("#chat-messages")
    this.classifyAll()
    this.scrollToStart()
    this.observeMutations()
    this.scheduleMarkAsRead()
    this.connectCable()
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.observer?.disconnect()
    clearTimeout(this._readTimer)
  }

  // --- Scroll ---

  scrollToStart() {
    const divider = this.messagesEl.querySelector("#new-messages-divider")
    if (divider) {
      divider.scrollIntoView({ block: "center" })
    } else {
      this.scrollToBottom()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  // --- Mutations (Turbo Stream appends) ---

  observeMutations() {
    this.observer = new MutationObserver((mutations) => {
      const hasNewMessages = mutations.some((m) =>
        Array.from(m.addedNodes).some((n) => n.nodeType === 1 && n.classList?.contains("chat-msg"))
      )
      if (!hasNewMessages) return
      this.classifyAll()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesEl, { childList: true })
  }

  // --- ActionCable (optional, may fail) ---

  async connectCable() {
    try {
      const { default: consumer } = await import("channels/consumer")
      this.subscription = consumer.subscriptions.create(
        { channel: "JobChannel", job_id: this.jobIdValue },
        { received: (data) => this.appendMessage(data.message_html) }
      )
    } catch (e) {
      // ActionCable unavailable — Turbo Stream handles messages
    }
  }

  appendMessage(html) {
    const tmp = document.createElement("div")
    tmp.innerHTML = html
    const incoming = tmp.firstElementChild
    if (!incoming) return

    // Own messages arrive via Turbo Stream — skip ActionCable duplicate
    if (incoming.dataset.senderId === this.userIdValue) return

    const msgId = incoming.dataset.messageId
    if (msgId && this.messagesEl.querySelector(`[data-message-id="${msgId}"]`)) return

    const empty = this.messagesEl.querySelector("#chat-empty")
    if (empty) empty.remove()

    this.messagesEl.appendChild(incoming)
  }

  // --- Classification (mine / theirs) ---

  classifyAll() {
    this.messagesEl.querySelectorAll(".chat-msg:not(.mine):not(.theirs)").forEach((el) => {
      const senderId = el.dataset.senderId
      el.classList.add(senderId === this.userIdValue ? "mine" : "theirs")
    })
  }

  // --- Read tracking ---

  scheduleMarkAsRead() {
    if (!this.readUrlValue) return
    this._readTimer = setTimeout(() => this.markAsRead(), 3000)
  }

  markAsRead() {
    if (this._markedRead) return
    this._markedRead = true

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.readUrlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ job_id: this.jobIdValue }),
    }).then(() => {
      const divider = this.messagesEl.querySelector("#new-messages-divider")
      if (divider) divider.remove()
    }).catch(() => { this._markedRead = false })
  }
}
