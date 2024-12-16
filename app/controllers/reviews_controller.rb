class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review, only: %i[edit update destroy]

  def new
    @review = Review.new
    # レビューの新規作成時に、手放せるものリストのフォームを3つ表示
    3.times { @review.releasable_items.build }
  end

  def create
    @review = current_user.reviews.build(review_params)
    if @review.save
      redirect_to reviews_path, notice: "レビューを投稿しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @review = Review.find(params[:id])
  end

  def index
    @reviews = Review.includes(:user).all.order(created_at: :desc).page(params[:page])
  end

  def edit
      @review = current_user.reviews.find(params[:id])
      # 登録している手放せるものを差し引いた、空のフォームを追加
      remaining_slots = [ 3 - @review.releasable_items.size, 0 ].max
      remaining_slots.times { @review.releasable_items.build }
  end

  def update
    if @review.update(review_params)
      redirect_to @review, notice: "レビューを更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @review.destroy
      redirect_to reviews_path, notice: "レビューを削除しました。"
    else
      redirect_to reviews_path, alert: "レビューの削除に失敗しました。"
    end
  end

  private
  # accepts_nested_attributes_forで削除するものを_destroyを追加
  def review_params
    params.require(:review).permit(:title, :content, releasable_items_attributes: [ :id, :name, :_destroy ])
  end

  def set_review
    @review = current_user.reviews.find_by(id: params[:id])
    unless @review
      redirect_to review_path, alert: "他のユーザーのレビューは編集・削除できません。"
    end
  end
end
