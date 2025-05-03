import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  insert() {
    const template = `【商品の特徴】

【使ってみた感想】

【こんな人におすすめ】`;

    if (this.hasTextareaTarget) {
      const textarea = this.textareaTarget

      textarea.value = template

      textarea.focus()

      textarea.dispatchEvent(new Event("input"));
    }
  }
}
