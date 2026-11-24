import { Controller } from "@hotwired/stimulus"

// "Use my area": the phone rounds its location to a ~1 km grid square
// BEFORE anything is sent. The precise position never leaves the device.
export default class extends Controller {
  static targets = ["lat", "lng", "status", "button"]

  locate() {
    if (!navigator.geolocation) return this.say("This browser can't share an area. Use a venue code instead.")
    this.buttonTarget.disabled = true
    this.say("Finding your area…")
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latTarget.value = Math.floor(position.coords.latitude * 100)
        this.lngTarget.value = Math.floor(position.coords.longitude * 100)
        this.element.requestSubmit()
      },
      () => {
        this.buttonTarget.disabled = false
        this.say("No problem. Without your area, use a venue code instead.")
      },
      { enableHighAccuracy: false, maximumAge: 600000, timeout: 15000 }
    )
  }

  say(text) { this.statusTarget.textContent = text }
}
