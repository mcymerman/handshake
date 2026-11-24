import { Controller } from "@hotwired/stimulus"

// Alerts fade after a while; important ones stay until dismissed.
export default class extends Controller {
  static values = { sticky: Boolean }

  connect() { if (!this.stickyValue) this.timer = setTimeout(() => this.dismiss(), 9000) }
  disconnect() { clearTimeout(this.timer) }
  dismiss() { this.element.remove() }
}
