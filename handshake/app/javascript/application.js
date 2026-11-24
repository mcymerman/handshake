import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

const { StreamActions } = Turbo

// Server-pushed navigation: after a match, both phones open the new chat.
StreamActions.visit = function () {
  Turbo.visit(this.getAttribute("location"))
}

// Ask a Turbo frame to fetch itself again (fresh code, updated approvals).
StreamActions.reload_frame = function () {
  refreshFrame(document.getElementById(this.getAttribute("target")))
}

// A chat ended or you were removed: leave it if it's on screen.
StreamActions.leave_thread = function () {
  const message = this.getAttribute("message")
  const open = document.getElementById(this.getAttribute("target"))
  if (open) {
    document.addEventListener("turbo:load", () => showAlert(message), { once: true })
    Turbo.visit("/chats")
  } else {
    showAlert(message)
  }
}

function showAlert(text) {
  const box = document.getElementById("alerts")
  if (!box || !text) return
  const alert = document.createElement("div")
  alert.className = "alert"
  alert.setAttribute("role", "status")
  alert.dataset.controller = "alert"
  const span = document.createElement("span")
  span.textContent = text
  const close = document.createElement("button")
  close.type = "button"
  close.textContent = "×"
  close.setAttribute("aria-label", "Dismiss")
  close.dataset.action = "alert#dismiss"
  alert.append(span, close)
  box.append(alert)
}

// Frames carry data-refresh-url; the first refresh sets src, later ones reload.
export function refreshFrame(frame) {
  if (!frame) return
  if (frame.src) frame.reload()
  else if (frame.dataset.refreshUrl) frame.src = frame.dataset.refreshUrl
}
window.refreshFrame = refreshFrame
