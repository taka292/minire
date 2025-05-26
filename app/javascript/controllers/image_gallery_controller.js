import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "thumbnail"]

  connect() {
    this.highlight(0) // 初期選択を強調
  }

  change(event) {
    const largeUrl = event.currentTarget.dataset.large
    const index = parseInt(event.currentTarget.dataset.index)
    this.mainTarget.src = largeUrl
    this.highlight(index)
  }

  highlight(index) {
    this.thumbnailTargets.forEach((el, i) => {
      el.classList.toggle("border-2", i === index)
      el.classList.toggle("border-blue-500", i === index)
      el.classList.toggle("border-transparent", i !== index)
      el.classList.toggle("opacity-100", i === index)
      el.classList.toggle("opacity-60", i !== index)
    })
  }
}
