import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "removeImages"]

  connect() {
    this.selectedFiles = [];

    // 既存の画像をリストに追加
    this.element.querySelectorAll(".preview-image").forEach(imageElement => {
      const imageId = imageElement.dataset.imageId;
      if (imageId) {
        this.selectedFiles.push({ id: imageId, element: imageElement });
      }
    });

    this.updatePreview();
  }

  selectImages(event) {
    const files = Array.from(event.target.files);

    files.forEach(file => {
      if (
        !this.selectedFiles.some(
          f => f instanceof File &&
          f.name === file.name &&
          f.size === file.size &&
          f.lastModified === file.lastModified
        )
      ) {
        this.selectedFiles.push(file);
      }
    });

    this.updatePreview();
    this.updateFileInput();
  }

  updatePreview() {
    this.previewTarget.innerHTML = ""; // プレビューをリセット

    this.selectedFiles.forEach((file, index) => {
      const container = document.createElement("div");
      container.classList.add("relative", "preview-image");

      const removeBtn = document.createElement("button");
      removeBtn.innerText = "×";
      removeBtn.classList.add("ml-2", "text-red-500", "cursor-pointer");
      removeBtn.addEventListener("click", () => this.removeImage(index));

      if (file instanceof File) {
        const reader = new FileReader();
        reader.onload = (e) => {
          const img = document.createElement("img");
          img.src = e.target.result;
          img.classList.add("w-24", "h-24", "object-cover", "border");
          container.appendChild(img);
          container.appendChild(removeBtn);
          this.previewTarget.appendChild(container);
        };
        reader.readAsDataURL(file);
      } else {
        container.appendChild(file.element);
        container.appendChild(removeBtn);
        this.previewTarget.appendChild(container);
      }
    });
  }

  removeImage(index) {
    const file = this.selectedFiles[index];

    if (!(file instanceof File) && this.hasRemoveImagesTarget) {
      let currentValue = this.removeImagesTarget.value ? this.removeImagesTarget.value.split(',') : [];
      currentValue.push(file.id);
      this.removeImagesTarget.value = currentValue.join(',');
    }

    this.selectedFiles.splice(index, 1);
    this.updatePreview();
    this.updateFileInput();
  }

  updateFileInput() {
    const dataTransfer = new DataTransfer();
    this.selectedFiles.forEach(file => {
      if (file instanceof File) {
        dataTransfer.items.add(file);
      }
    });
    this.inputTarget.files = dataTransfer.files;
  }
}
