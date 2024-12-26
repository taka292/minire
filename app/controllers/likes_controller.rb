class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review, only: [ :create, :destroy ]

  def index
    @liked_reviews = current_user.liked_reviews.includes(:user, images_attachments: :blob)
  end

  def create
    like = @review.likes.new(user: current_user)
    like.save
    redirect_back fallback_location: @review
  end

  def destroy
    like = @review.likes.find_by(user: current_user)
    like&.destroy
    redirect_back fallback_location: @review
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end
end
