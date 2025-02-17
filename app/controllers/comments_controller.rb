class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [ :destroy ]

  def create
    @review = Review.find(params[:review_id])
    @comment = @review.comments.build(comment_params.merge(user: current_user))
    if @comment.save
      redirect_to @review, notice: "コメントを投稿しました！"
    else
      redirect_to @review, alert: "コメントの投稿に失敗しました。"
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      redirect_to @comment.review, notice: "コメントを削除しました。"
    else
      redirect_to @comment.review, alert: "コメントの削除権限がありません。"
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
