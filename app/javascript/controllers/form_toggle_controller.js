import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "formArea", "title"]
  static values = { index: Number }

  connect() {
    this.indexValue = 0
  }

  add(event) {
    event.preventDefault()
    if (this.indexValue >= 3) return

    // 最初の追加時にタイトル表示
    if (this.indexValue === 0) {
      this.titleTarget.classList.remove("hidden")
    }

    const content = this.templateTarget.innerHTML.replace(/__INDEX__/g, this.indexValue)
    this.formAreaTarget.insertAdjacentHTML("beforeend", content)
    this.indexValue++
  }
}
