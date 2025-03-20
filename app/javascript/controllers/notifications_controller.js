import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    console.log("NotificationsController connected");

    // ページを離れる前に既読処理を実行
    window.addEventListener("beforeunload", this.markAsRead.bind(this));
  }

  disconnect() {
    // イベントリスナーを削除（不要なリスナー登録を防ぐ）
    window.removeEventListener("beforeunload", this.markAsRead.bind(this));
  }

  async markAsRead() {
    try {
      await fetch("/notifications/update_checked", {
        method: "POST",
        headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
      });
      console.log("Notifications marked as read");
    } catch (error) {
      console.error("Failed to mark notifications as read:", error);
    }
  }
}
