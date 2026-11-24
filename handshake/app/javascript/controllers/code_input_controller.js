import { Controller } from "@hotwired/stimulus"

// Formats typed digits as 47-12-83 and clears the box after a success.
export default class extends Controller {
  static targets = ["input"]

  format() {
    const digits = this.inputTarget.value.replace(/\D/g, "").slice(0, 6)
    this.inputTarget.value = digits.match(/.{1,2}/g)?.join("-") ?? ""
  }

  done(event) {
    if (event.detail.success) this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}
