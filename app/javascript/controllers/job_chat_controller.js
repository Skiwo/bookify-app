import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { jobId: String, userId: String }

  connect() {
    this.messagesEl = this.element.querySelector("#chat-messages")
    this.classifyAll()
    this.scrollToBottom()
    this.observeMutations()
    this.connectCable()
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.observer?.disconnect()
  }

  observeMutations() {
    this.observer = new MutationObserver(() => {
      this.classifyAll()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesEl, { childList: true })
  }

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

    const msgId = incoming.dataset.messageId
    if (msgId && this.messagesEl.querySelector(`[data-message-id="${msgId}"]`)) return

    const empty = this.messagesEl.querySelector("#chat-empty")
    if (empty) empty.remove()

    this.messagesEl.appendChild(incoming)
  }

  classifyAll() {
    this.messagesEl.querySelectorAll(".chat-msg:not(.mine):not(.theirs)").forEach((el) => {
      const senderId = el.dataset.senderId
      el.classList.add(senderId === this.userIdValue ? "mine" : "theirs")
    })
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
