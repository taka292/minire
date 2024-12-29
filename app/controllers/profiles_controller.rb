class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    # @reviews = @user.reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    # # @liked_reviews はデフォルトではセットしない
    # @liked_reviews = nil
    @reviews = @user.reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    @active_tab = "reviews"
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

  # def reviews
  #   @reviews = @user.reviews.includes(:user, :likes, images_attachments: :blob).order(created_at: :desc).page(params[:page])
  #   @liked_reviews = [] # 初期化
  #   render :show
  # end

  def likes
    # @liked_reviews = @user.liked_reviews.includes(:user, :likes, images_attachments: :blob).order(created_at: :desc).page(params[:page])
    # @reviews = [] # 初期化
    # render :show
    @liked_reviews = @user.liked_reviews.includes(:user, images_attachments: :blob).order(created_at: :desc)
    @active_tab = "likes"
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
