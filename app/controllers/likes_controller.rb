class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review, only: [ :create, :destroy ]

  def create
    @like = @review.likes.new(user: current_user)
    respond_to do |format|
      if @like.save
        if current_user != @review.user
          @review.create_notification_favorite_review!(current_user)
        end
        format.turbo_stream
        format.html { redirect_to @review }
      else
        format.html { redirect_to @review }
      end
    end
  end

  def destroy
    @like = @review.likes.find_by(user: current_user)
    respond_to do |format|
      if @like&.destroy
        format.turbo_stream
        format.html { redirect_to @review }
      else
        format.html { redirect_to @review }
      end
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end
end
