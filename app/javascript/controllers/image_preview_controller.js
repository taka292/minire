import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "removeImages"];

  // コントローラが接続されたときに実行される初期化処理
  connect() {
    // 既存のプレビュー画像を取得し、selectedFiles に格納
    this.selectedFiles = Array.from(
      this.element.querySelectorAll(".preview-image")
    // 新しく追加された画像は対象外
    ).map(img => ({ id: img.dataset.imageId, element: img })).filter(f => f.id);
    
    // プレビューを表示
    this.renderPreview();
  }

  // ユーザーが新しい画像を選択したときの処理
  selectImages(event) {
    // 入力されたファイルリストを取得し、重複しないものだけを選別
    const files = Array.from(event.target.files).filter(file => 
      !this.selectedFiles.some(f => f instanceof File && this.isSameFile(f, file))
    );
    
    // 選択されたファイルを selectedFiles に追加
    this.selectedFiles.push(...files);
    
    // プレビューを更新
    this.renderPreview();
    
    // フォームの file input の内容を更新
    this.syncFileInput();
  }

  // プレビュー領域を更新する処理
  renderPreview() {
    // 既存のプレビューをクリア
    this.previewTarget.innerHTML = "";
    
    // 選択されたファイルごとにプレビューを生成
    this.selectedFiles.forEach((file, index) => {
      const container = document.createElement("div");
      container.classList.add("relative", "preview-image");

      // 画像削除ボタンを作成
      const removeBtn = document.createElement("button");
      removeBtn.innerText = "×";
      removeBtn.classList.add("ml-2", "text-red-500", "cursor-pointer", "text-lg", "font-bold", "w-6", "h-6","flex", "items-center", "justify-center","absolute", "top-0", "right-0",  "bg-white", "rounded-full", "shadow" )
      removeBtn.onclick = () => this.removeImage(index);

      if (file instanceof File) {
        // 新しく追加されたファイルの場合、FileReader で画像を読み込んで表示
        const reader = new FileReader();
        reader.onload = e => container.append(...this.createImageElements(e.target.result, removeBtn));
        reader.readAsDataURL(file);
      } else {
        // すでに登録されている画像はそのまま表示
        container.append(file.element, removeBtn);
      }
      
      // プレビュー領域に追加
      this.previewTarget.appendChild(container);
    });
  }

  // 指定された画像を削除する処理
  removeImage(index) {
    // 指定したインデックスのファイルを selectedFiles から削除
    const file = this.selectedFiles.splice(index, 1)[0];
    
    // すでにアップロードされている画像（File ではないもの）なら、削除リストに追加
    if (!(file instanceof File) && this.hasRemoveImagesTarget) {
      this.removeImagesTarget.value = [this.removeImagesTarget.value, file.id].filter(Boolean).join(",");
    }
    
    // プレビューを再描画
    this.renderPreview();
    
    // フォームの file input を更新
    this.syncFileInput();
  }

  // フォームの file input の値を更新する処理
  syncFileInput() {
    const dataTransfer = new DataTransfer();
    
    // File オブジェクトのみをデータに追加
    this.selectedFiles.filter(f => f instanceof File).forEach(f => dataTransfer.items.add(f));
    
    // file input にセット
    this.inputTarget.files = dataTransfer.files;
  }

  // 二つのファイルが同じかを判定するメソッド
  isSameFile(file1, file2) {
    return file1.name === file2.name && file1.size === file2.size && file1.lastModified === file2.lastModified;
  }

  // 画像要素と削除ボタンを作成するヘルパーメソッド
  createImageElements(src, removeBtn) {
    const img = document.createElement("img");
    img.src = src;
    img.classList.add("w-24", "h-24", "object-cover", "border");
    return [img, removeBtn];
  }
}