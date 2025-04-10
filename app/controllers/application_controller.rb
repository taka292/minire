class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unchecked_notifications

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :introduction, :avatar ])
  end

  def set_unchecked_notifications
    return unless user_signed_in?

    @unchecked_notifications = current_user.passive_notifications.where(checked: false).order(created_at: :desc)
  end
end
