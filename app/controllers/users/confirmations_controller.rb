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

  # GET /resource/confirmation?confirmation_token=abcdef
  # def show
  #   super
  # end

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
