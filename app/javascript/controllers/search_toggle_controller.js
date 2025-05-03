import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 	フォーム表示時に、「search_method」の値に応じて動的に検索フォームを切り替える
  connect() {
    const method = document.getElementById("search_method")?.value || "amazon"
    this.toggle(method)
  }

  // 	フォームの表示・非表示を切り替える
  toggle(method) {
    const amazonForm = document.getElementById("amazon-form")
    const minireForm = document.getElementById("minire-form")
    const methodField = document.getElementById("search_method")

    if (method === "minire") {
      amazonForm?.classList.add("hidden")
      minireForm?.classList.remove("hidden")
    } else {
      amazonForm?.classList.remove("hidden")
      minireForm?.classList.add("hidden")
    }
    // 切り替えた検索方法を hidden フィールドに反映
    if (methodField) methodField.value = method
  }

  // 	amazonの検索フォームを表示
  showMinire() {
    this.toggle("minire")
  }

  // 	サイト内(見つからない場合)の検索フォームを表示
  showAmazon() {
    this.toggle("amazon")
  }
}
