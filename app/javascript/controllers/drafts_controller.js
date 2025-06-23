import { Controller } from "@hotwired/stimulus"

// 下書きのモーダル表示の制御
export default class extends Controller {
  connect() {
    this.modal = document.getElementById("draftModal")
    console.log("DraftsController connected")
  }

  open() {
    console.log("DraftsController open")
    this.modal.classList.remove("hidden")
    this.modal.classList.add("flex")
  }

  close() {
    this.modal.classList.add("hidden")
    this.modal.classList.remove("flex")
  }
}

