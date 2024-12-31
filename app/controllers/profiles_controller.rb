class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    @reviews = @user.reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    @active_tab = "reviews"
  end

  def edit
  end

  # メールアドレス変更フォーム表示
  def edit_email
  end

  # プロフィール情報（名前、自己紹介、アバター画像）の更新
  def update
    if @user.update(profile_params)
      redirect_to profile_path(@user), notice: "プロフィールを更新しました！"
    else
      flash.now[:alert] = "プロフィールの更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
  end

  # メールアドレス更新処理
  def update_email
    if @user.update(email_update_params)
      redirect_to profile_path(@user), notice: "確認メールを送信しました。メール内のリンクをクリックしてメールアドレスを確認してください。"
    else
      flash.now[:alert] = "メールアドレスの更新に失敗しました。"
      render :edit_email, status: :unprocessable_entity
    end
  end

  def likes
    @liked_reviews = @user.liked_reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    @active_tab = "likes"
    render :show
  end

  private

  def set_user
    @user = User.find(params[:id]) # 表示するユーザーを取得
  end

  def profile_params
    params.require(:user).permit(:name, :introduction, :avatar)
  end

  def email_update_params
    params.require(:user).permit(:email) # メールアドレスの変更を許可
  end
end
