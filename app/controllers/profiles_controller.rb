class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :reject_sns_user, only: [ :edit_email, :edit_password ]

  def show
    @reviews = @user.reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    @active_tab = "reviews"
  end

  def edit
  end

  # メールアドレス変更フォーム表示
  def edit_email
  end

  # パスワード変更用フォームの表示
  def edit_password
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

  # パスワード更新処理
  def update_password
    if @user.update_with_password(password_update_params)
      bypass_sign_in(@user) # サインイン状態を維持
      redirect_to profile_path(@user), notice: "パスワードを変更しました！"
    else
      flash.now[:alert] = "パスワードの変更に失敗しました。"
      render :edit_password, status: :unprocessable_entity
    end
  end

  def likes
    # @userがいいねしたレビューをいいねした日時の降順で取得
    # includesメソッドを使用して、関連するユーザーと画像を事前に読み込む
    @liked_reviews = @user.likes
                      .includes(review: [ :user, { images_attachments: :blob } ])
                      .order(created_at: :desc)
                      .map(&:review)
    @active_tab = "likes"
    render :show
  end

  private

  def set_user
    @user = User.find(params[:id]) # 表示するユーザーを取得
  end

  def profile_params
    params.require(:user).permit(:name, :introduction, :avatar, :instagram_id, :x_id, :youtube_id, :note_id)
  end

  def email_update_params
    params.require(:user).permit(:email) # メールアドレスの変更を許可
  end

  def password_update_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  # SNSログインユーザーはメールアドレスとパスワードの変更を拒否
  def reject_sns_user
    if current_user.provider.present?
      redirect_to profile_path(current_user), alert: "SNSログインユーザーはこの操作を行えません。"
    end
  end
end
