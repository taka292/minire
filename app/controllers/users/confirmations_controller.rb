# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  # def create
  #   super
  # end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      # 正常に確認された場合のリダイレクト
      redirect_to edit_profile_path(resource), notice: "メールアドレスの確認が完了しました。"
    elsif resource.confirmed?
      # 既に確認済みの場合のリダイレクト
      redirect_to edit_profile_path(resource), alert: "このメールアドレスは既に確認済みです。"
    else
      # その他のエラーの場合はデフォルトの処理
      super
    end
  end

  protected



  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # メール確認後のリダイレクト先を指定
  def after_confirmation_path_for(resource_name, resource)
    edit_profile_path(resource) # プロフィール編集ページにリダイレクト
  end
end
