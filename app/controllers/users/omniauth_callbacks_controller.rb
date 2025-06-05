# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # deviseのログイン保持機能を読み込み
  include Devise::Controllers::Rememberable

  # callback for google
  def google_oauth2
    callback_for(:google)
  end

  def callback_for(provider)
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    # SNSログインに成功した場合、ログイン保持状態をON
    if @user.persisted?
      remember_me(@user)
      flash[:notice] = "Google認証成功しました！さっそくレビューを投稿してみませんか？" unless @user.has_reviews?
      sign_in_and_redirect @user, event: :authentication
    else
      if User.exists?(email: auth.info.email)
        # 同じメールで登録済み → 通常ログインを案内
        redirect_to new_user_session_path, alert: "このメールアドレスは別のログイン方法で既に登録されています。登録時の方法（通常登録またはSNS認証）でログインしてください。"
      else
        # その他の失敗（例：不明なエラーなど）
        redirect_to new_user_registration_path, alert: "認証に失敗しました。もう一度お試しください。"
      end
    end
  end

  def failure
    redirect_to root_path
  end
end
