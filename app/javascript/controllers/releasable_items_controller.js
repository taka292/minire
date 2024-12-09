import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const addButton = document.getElementById("add-releasable-item");
    addButton.addEventListener("click", () => {
      const container = document.getElementById("releasable-items-fields");
      const count = container.children.length;

      if (count < 10) {
        const input = document.createElement("input");
        input.type = "text";
        input.name = `review[releasable_items_attributes][${count}][name]`;
        input.className = "input input-bordered w-full mb-2";
        input.placeholder = "手放せるものを入力してください";
        container.appendChild(input);
      }
    });
  }
}
