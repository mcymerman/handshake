import { Controller } from "@hotwired/stimulus"

// Enter sends, Shift+Enter adds a line, and the box clears after sending.
export default class extends Controller {
  static targets = ["body"]

  key(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.bodyTarget.value.trim() !== "") this.element.requestSubmit()
    }
  }

  sent(event) {
    if (event.detail.success) {
      this.bodyTarget.value = ""
      this.bodyTarget.focus()
    }
  }
}
