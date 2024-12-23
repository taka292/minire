class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @review = Review.find(params[:review_id])
    @comment = @review.comments.build(comment_params.merge(user: current_user))
    if @comment.save
      redirect_to @review, notice: "コメントを投稿しました！"
    else
      redirect_to @review, alert: "コメントの投稿に失敗しました。"
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
