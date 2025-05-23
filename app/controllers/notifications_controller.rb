class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # @unchecked_notifications = current_user.passive_notifications.where(checked: false).order(created_at: :desc)
    @checked_notifications = current_user.passive_notifications.where(checked: true).order(created_at: :desc).limit(20)

    # 全通知を既読にする
    # @unchecked_notifications.update_all(checked: true)

    # 通知一覧ページをレンダリング
    render "notifications/index"
  end

  def update_checked
    current_user.passive_notifications.update_all(checked: true)
    redirect_to notifications_path, notice: "通知をすべて既読にしました"
  end
end
