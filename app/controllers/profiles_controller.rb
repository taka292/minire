class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    @reviews = @user.reviews.includes(:likes) # デフォルトは過去のレビューを表示
    @liked_reviews = nil
  end

  def edit
  end

  def update
    # if @user.update(profile_params)
    #   redirect_to profile_path(@user), notice: "プロフィールを更新しました！"
    # else
    #   render :edit, status: :unprocessable_entity
    # end
  end

  def reviews
    @reviews = @user.reviews.includes(:user, :likes) # 過去のレビュー
    @liked_reviews = nil
    render :show
  end

  def likes
    @liked_reviews = @user.liked_reviews.includes(:user, :likes) # いいねしたレビュー
    @reviews = nil
    render :show
  end

  private

  def set_user
    @user = User.find(params[:id]) # 表示するユーザーを取得
  end

  def profile_params
    params.require(:user).permit(:name, :email, :introduction, :avatar)
  end
end
