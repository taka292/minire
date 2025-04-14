import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const method = document.getElementById("search_method")?.value || "amazon"
    this.toggle(method)
  }

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

    if (methodField) methodField.value = method
  }

  showMinire() {
    this.toggle("minire")
  }

  showAmazon() {
    this.toggle("amazon")
  }
}
