import { Controller } from "@hotwired/stimulus"

// Shrinks a chosen photo to 320px on the phone before upload.
export default class extends Controller {
  static targets = ["file", "data", "preview", "remove"]

  pick() {
    const file = this.fileTarget.files[0]
    if (!file) return
    const image = new Image()
    image.onload = () => {
      const size = 320
      const scale = Math.min(1, size / Math.max(image.width, image.height))
      const canvas = document.createElement("canvas")
      canvas.width = Math.round(image.width * scale)
      canvas.height = Math.round(image.height * scale)
      canvas.getContext("2d").drawImage(image, 0, 0, canvas.width, canvas.height)
      this.show(canvas.toDataURL("image/jpeg", 0.82))
      URL.revokeObjectURL(image.src)
    }
    image.src = URL.createObjectURL(file)
  }

  clear() {
    this.fileTarget.value = ""
    this.show("")
  }

  show(dataUrl) {
    this.dataTarget.value = dataUrl
    this.previewTarget.src = dataUrl
    this.previewTarget.hidden = dataUrl === ""
    this.removeTarget.hidden = dataUrl === ""
  }
}
