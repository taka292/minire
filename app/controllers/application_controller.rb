class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unchecked_notifications
  before_action :prepare_ransack_query

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :introduction, :avatar ])
  end

  # 未読通知を取得
  def set_unchecked_notifications
    return unless user_signed_in?

    @unchecked_notifications = current_user.passive_notifications.includes_for_notification.where(checked: false).order(created_at: :desc)
  end

  # 全ページで使用するransackの初期化(無いとエラーになる)
  def prepare_ransack_query
    @q = Review.ransack(params[:q])
  end
end
