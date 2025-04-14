import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.adjust()
  }

  resize() {
    this.adjust()
  }

  adjust() {
    this.element.style.height = 'auto' // 高さをリセット
    this.element.style.height = this.element.scrollHeight + 'px' // 内容に応じた高さに再設定
  }
}
