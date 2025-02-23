class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_commentable, only: %i[create]
  before_action :set_comment, only: %i[destroy]

  def create
    @comment = @commentable.comments.build(comment_params.merge(user: current_user))
    @comments = @commentable.comments.includes(:user)

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to @commentable }
      else
        # format.turbo_stream do
        #   flash.now[:danger] = t('defaults.message.not_created', item: Comment.model_name.human)
        # render turbo_stream: [
        #   turbo_stream.replace("flash_messages", partial: "shared/flash_messages"),
        # ]
        # end
        format.html { redirect_to @commentable }
      end
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @comment.commentable, notice: "コメントを削除しました。" }
      end
    else
      redirect_to @comment.commentable, alert: "コメントの削除権限がありません。"
    end
  end

  private

  def set_comment
    @comment = current_user.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def find_commentable
    @commentable = Review.find(params[:review_id])
  end
end
