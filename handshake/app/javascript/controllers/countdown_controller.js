import { Controller } from "@hotwired/stimulus"

// Counts down a code's life and fetches a fresh one at zero.
export default class extends Controller {
  static targets = ["label", "ring"]
  static values = { seconds: Number, total: Number }

  connect() {
    this.endsAt = Date.now() + this.secondsValue * 1000
    this.tick()
    this.timer = setInterval(() => this.tick(), 250)
  }

  disconnect() { clearInterval(this.timer) }

  tick() {
    const left = Math.max(0, Math.ceil((this.endsAt - Date.now()) / 1000))
    if (this.hasLabelTarget) this.labelTarget.textContent = `${left}s`
    if (this.hasRingTarget) {
      const circumference = 2 * Math.PI * 45
      this.ringTarget.style.strokeDasharray = `${circumference}`
      this.ringTarget.style.strokeDashoffset = `${circumference * (1 - left / this.totalValue)}`
    }
    this.element.classList.toggle("is-ending", left <= 10)
    if (left === 0) {
      clearInterval(this.timer)
      const frame = this.element.closest("turbo-frame")
      if (frame) window.refreshFrame(frame)
      else Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
