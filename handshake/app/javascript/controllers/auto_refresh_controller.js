import { Controller } from "@hotwired/stimulus"

// Gentle fallback refresh for screens that also get live updates.
export default class extends Controller {
  static values = { seconds: { type: Number, default: 30 } }

  connect() { this.timer = setTimeout(() => Turbo.visit(window.location.href, { action: "replace" }), this.secondsValue * 1000) }
  disconnect() { clearTimeout(this.timer) }
}
