import { Controller } from "@hotwired/stimulus"

// Keeps messages in sequence order, marks your own, and scrolls to the latest.
export default class extends Controller {
  static values = { me: String }

  connect() {
    this.observer = new MutationObserver(() => this.arrange())
    this.observer.observe(this.element, { childList: true })
    this.arrange()
    // Phones pause background tabs; catch up on anything missed when we're back.
    this.onVisibility = () => {
      if (document.hidden) this.hiddenAt = Date.now()
      else if (this.hiddenAt && Date.now() - this.hiddenAt > 5000) Turbo.visit(window.location.href, { action: "replace" })
    }
    document.addEventListener("visibilitychange", this.onVisibility)
  }

  disconnect() {
    this.observer.disconnect()
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  arrange() {
    this.observer.disconnect()
    const items = [...this.element.querySelectorAll(":scope > [data-seq]")]
    const sorted = [...items].sort((a, b) => Number(a.dataset.seq) - Number(b.dataset.seq))
    if (sorted.some((el, i) => el !== items[i])) sorted.forEach((el) => this.element.appendChild(el))
    sorted.forEach((el) => el.classList.toggle("mine", el.dataset.author === this.meValue))
    this.observer.observe(this.element, { childList: true })
    this.element.scrollTop = this.element.scrollHeight
    window.scrollTo(0, document.body.scrollHeight)
  }
}
