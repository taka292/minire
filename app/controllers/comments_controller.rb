class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_review, only: %i[create edit destroy]
  before_action :find_comment, only: %i[destroy edit update]

  def create
    @comment = @review.comments.build(comment_params.merge(user: current_user))

    respond_to do |format|
      if @comment.save
        # コメントの投稿に対する通知を作成・保存
        @review.create_notification_comment!(current_user, @comment.id)
        format.turbo_stream { flash.now[:comment_notice] = "コメントを投稿しました。" }
        format.html { redirect_to @review, flash: { comment_notice: "コメントを投稿しました。" } }
      else
        format.turbo_stream do
          flash.now[:comment_alert] = "コメントの投稿に失敗しました。"
          render turbo_stream: [
            turbo_stream.replace("flash_message", partial: "shared/flash_message_turbo")
          ]
        end
        format.html { redirect_to @review, flash: { comment_alert: "コメントの投稿に失敗しました。" } }
      end
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      respond_to do |format|
        format.turbo_stream  { flash.now[:comment_notice] = "コメントを削除しました。" }
        format.html { redirect_to @comment.review, comment_notice: "コメントを削除しました。" }
      end
    else
      redirect_to @comment.review, comment_alert: "コメントの削除権限がありません。"
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream { flash.now[:comment_notice] = "コメントを編集しました。" }
        format.html { redirect_to @comment.review, comment_notice: "コメントを編集しました。" }
      else
        format.turbo_stream do
          flash.now[:comment_alert] = "コメントの編集に失敗しました。"
          render turbo_stream: [
            turbo_stream.replace("flash_message", partial: "shared/flash_message_turbo")
          ]
        end
        format.html { redirect_to @comment.review, comment_alert: "コメントの編集に失敗しました。" }
      end
    end
  end

  private

  def find_comment
    @comment = current_user.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def find_review
    @review = Review.find(params[:review_id])
  end
end
