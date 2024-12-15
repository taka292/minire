// stimulusを用いた、手放せるものの非同期フォームは別途追加実装予定

// import { Controller } from "@hotwired/stimulus";
// 
// export default class extends Controller {
//   connect() {
//     const addButton = document.getElementById("add-releasable-item");
//     const container = document.getElementById("releasable-items-fields");
// 
//     // ボタンの初期状態をチェック
//     this.updateButtonState(addButton);
// 
//     // 入力欄に入力があるかチェック
//     container.addEventListener("input", (event) => {
//       this.updateButtonState(addButton);
//     });
// 
//     // ボタンが押されたときの動作
//     addButton.addEventListener("click", () => {
//       const count = container.children.length;
// 
//       if (count < 5) {
//         const input = document.createElement("input");
//         input.type = "text";
//         input.name = `review[releasable_items_attributes][${count}][name]`;
//         input.className = "input input-bordered w-full mb-2";
//         input.placeholder = "手放せるものを入力してください";
// 
//         container.appendChild(input);
// 
//         // 入力欄を追加したらボタンの状態を更新
//         this.updateButtonState(addButton);
//       }
//     });
//   }
// 
//   // ボタンの有効・無効を更新する関数
//   updateButtonState(button) {
//     const inputs = document.querySelectorAll("#releasable-items-fields input");
//     const isAnyInputEmpty = Array.from(inputs).some((input) => input.value.trim() === "");
// 
//     button.disabled = isAnyInputEmpty;
//     if (isAnyInputEmpty) {
//       button.classList.add("opacity-50", "cursor-not-allowed");
//     } else {
//       button.classList.remove("opacity-50", "cursor-not-allowed");
//     }
//   }
// }
