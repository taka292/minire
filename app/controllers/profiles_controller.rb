class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    # @reviews = @user.reviews.order(created_at: :desc).page(params[:page])
    # @liked_reviews = @user.likes.includes(:review).map(&:review)
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

#   def reviews
#     @reviews = @user.reviews.order(created_at: :desc).page(params[:page])
#     render :show
#   end
# 
#   def likes
#     @liked_reviews = @user.likes.includes(:review).map(&:review)
#     render :show
#   end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :email, :introduction, :avatar)
  end
end
