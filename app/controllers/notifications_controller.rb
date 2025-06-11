class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 既読通知を取得
    @checked_notifications = current_user.passive_notifications.includes_for_notification.where(checked: true).order(created_at: :desc).limit(20)

    # 通知一覧ページをレンダリング
    render "notifications/index"
  end

  # 未読通知を一括既読にする
  def update_checked
    current_user.passive_notifications.update_all(checked: true)
    redirect_to notifications_path, notice: "通知をすべて既読にしました"
  end
end
