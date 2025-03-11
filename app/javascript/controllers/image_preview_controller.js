import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "removeImages"];

  connect() {
    this.selectedFiles = Array.from(
      this.element.querySelectorAll(".preview-image")
    ).map(img => ({ id: img.dataset.imageId, element: img })).filter(f => f.id);
    this.renderPreview();
  }

  selectImages(event) {
    const files = Array.from(event.target.files).filter(file => 
      !this.selectedFiles.some(f => f instanceof File && this.isSameFile(f, file))
    );
    this.selectedFiles.push(...files);
    this.renderPreview();
    this.syncFileInput();
  }

  renderPreview() {
    this.previewTarget.innerHTML = "";
    this.selectedFiles.forEach((file, index) => {
      const container = document.createElement("div");
      container.classList.add("relative", "preview-image");

      const removeBtn = document.createElement("button");
      removeBtn.innerText = "×";
      removeBtn.classList.add("ml-2", "text-red-500", "cursor-pointer");
      removeBtn.onclick = () => this.removeImage(index);

      if (file instanceof File) {
        const reader = new FileReader();
        reader.onload = e => container.append(...this.createImageElements(e.target.result, removeBtn));
        reader.readAsDataURL(file);
      } else {
        container.append(file.element, removeBtn);
      }
      this.previewTarget.appendChild(container);
    });
  }

  removeImage(index) {
    const file = this.selectedFiles.splice(index, 1)[0];
    if (!(file instanceof File) && this.hasRemoveImagesTarget) {
      this.removeImagesTarget.value = [this.removeImagesTarget.value, file.id].filter(Boolean).join(",");
    }
    this.renderPreview();
    this.syncFileInput();
  }

  syncFileInput() {
    const dataTransfer = new DataTransfer();
    this.selectedFiles.filter(f => f instanceof File).forEach(f => dataTransfer.items.add(f));
    this.inputTarget.files = dataTransfer.files;
  }

  isSameFile(file1, file2) {
    return file1.name === file2.name && file1.size === file2.size && file1.lastModified === file2.lastModified;
  }

  createImageElements(src, removeBtn) {
    const img = document.createElement("img");
    img.src = src;
    img.classList.add("w-24", "h-24", "object-cover", "border");
    return [img, removeBtn];
  }
}
