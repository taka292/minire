import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "title"]

  connect() {
    // フォームが1つでも表示されていたらタイトル表示（編集時対応）
    if (this.itemTargets.some(el => !el.classList.contains("hidden"))) {
      this.titleTarget.classList.remove("hidden")
    }
  }

  add() {
    const hiddenItems = this.itemTargets.filter(el => el.classList.contains("hidden"))
    if (hiddenItems.length > 0) {
      hiddenItems[0].classList.remove("hidden")
    }

    // 初めて追加されたときにタイトルを表示
    if (this.titleTarget.classList.contains("hidden")) {
      this.titleTarget.classList.remove("hidden")
    }
  }
}
