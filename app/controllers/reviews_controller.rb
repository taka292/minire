class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def new
    @review = Review.new
    @review.releasable_items.build
    # @review.releasable_items.build
  end

  def create
    # @review = current_user.reviews.build(review_params)
    @review = current_user.reviews.build(review_params)
    # @review = Review.new(review_params)
    if @review.save
      redirect_to @review, notice: "レビューを投稿しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @review = Review.find(params[:id])
  end

  private

  def review_params
    params.require(:review).permit(:title, :content, releasable_items_attributes: [ :id, :name ])
    # 手放せるものリストの削除機能時には下記に修正
    # params.require(:review).permit(:title, :content, releasable_items_attributes: [:id, :name, :_destroy])
  end
end
