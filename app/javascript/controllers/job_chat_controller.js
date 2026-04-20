import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = { jobId: String }

  connect() {
    this.messagesEl = this.element.querySelector("#chat-messages")
    this.subscription = consumer.subscriptions.create(
      { channel: "JobChannel", job_id: this.jobIdValue },
      { received: (data) => this.appendMessage(data.message_html) }
    )
    this.scrollToBottom()
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  appendMessage(html) {
    const empty = this.messagesEl.querySelector("#chat-empty")
    if (empty) empty.remove()

    this.messagesEl.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
