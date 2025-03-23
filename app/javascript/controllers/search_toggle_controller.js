import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const selected = event.target.value
    const minire = document.getElementById("minire-form")
    const amazon = document.getElementById("amazon-form")

    if (selected === "minire") {
      minire.classList.remove("hidden")
      amazon.classList.add("hidden")
    } else {
      amazon.classList.remove("hidden")
      minire.classList.add("hidden")
    }
  }
}
