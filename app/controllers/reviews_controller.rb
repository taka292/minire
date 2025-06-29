class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_review, only: %i[edit update destroy]

  def new
    @review = Review.new
  end

  def create
    @review = current_user.reviews.build(review_params)

    # レビューと商品情報を関連付け、どちらかの保存に失敗した場合は、トランザクションをロールバック
    result = ActiveRecord::Base.transaction do
      # 商品情報をパラメータに基づいて取得・作成し、レビューに関連付ける
      unless ReviewItemAssignmentService.new(@review, params).call
        raise ActiveRecord::Rollback
      end

      # レビューの状態をもとに
      if params[:draft].present?
        @review.status = :draft
      else
        @review.status = :published
      end

      unless @review.save
        raise ActiveRecord::Rollback
      end

      # レビューに関連付けられた商品に画像(1枚目)を添付する
      attach_image_to_item_if_needed

      if params[:draft].present?
        redirect_to edit_review_path(@review), notice: "レビューを下書き保存しました！"
      else
        redirect_to reviews_path, notice: "レビューを投稿しました！"
      end
    end

    render :new, status: :unprocessable_entity unless result
  end

  def show
    # レビューの詳細情報取得
    @review = Review.find(params[:id])

    # レビューが下書きで、現在のユーザーがレビューの作成者でない場合はアクセスを制限
    if @review.draft? && @review.user != current_user
      redirect_to reviews_path, alert: "このレビューにはアクセスできません。"
      return
    end

    # レビューに紐づくコメントの読み込み
    @comments = @review.comments.includes(user: { avatar_attachment: :blob }).order(created_at: :desc)
    # コメント新規作成フォーム用
    @comment = @review.comments.new
  end

  def index
    # 良いね順かそれ以外でレビューを取得
    if params[:sort] == "most_liked"
      @reviews = Review.with_likes_count
    else
      @reviews = Review.includes_for_index
    end

    # 絞り込み
    @reviews = filter_reviews(@reviews)

    # 検索
    @search = @reviews.ransack(params[:q])
    @reviews = @search.result(distinct: true)

    # 並び替え + ページネーション
    @reviews = @reviews.published.apply_sort(params[:sort]).order(created_at: :desc).page(params[:page])

    @categories = Category.ordered
  end

  def edit
  end

  def update
    # レビューと商品情報を関連付け、どちらかの保存に失敗した場合は、トランザクションをロールバック
    result = ActiveRecord::Base.transaction do
      # 商品情報をパラメータに基づいて取得・作成し、レビューに関連付ける
      unless ReviewItemAssignmentService.new(@review, params).call
        raise ActiveRecord::Rollback
      end

      handle_image_removal
      @review.images.attach(params[:review][:images]) if params[:review][:images].present?

      # レビューの状態をもとに
      if params[:draft].present?
        @review.status = :draft
      else
        @review.status = :published
      end

      # レビュー更新 (item_id はservice側で設定済みのため、paramsに含まれる空文字で上書きされるのを防ぐ)
      raise ActiveRecord::Rollback unless @review.update(review_params.except(:images, :item_id))
      # attach_image_to_item_if_needed # 画像をitemに添付処理はリファクタリングとは別で対応

      if params[:draft].present?
        redirect_to edit_review_path(@review), notice: "レビューを下書き保存しました！"
      else
        redirect_to @review, notice: "レビューを更新しました！"
      end
    end

    render :edit, status: :unprocessable_entity unless result
  end

  def destroy
    if @review.destroy
      redirect_to reviews_path, notice: "レビューを削除しました。"
    else
      redirect_to reviews_path, alert: "レビューの削除に失敗しました。"
    end
  end

  private
  # accepts_nested_attributes_forで削除するものを_destroyで追加
  def review_params
    params.require(:review).permit(:title, :content, :category_id, :item_id, images: [], releasable_items_attributes: [ :id, :name, :_destroy ])
  end

  def set_review
    @review = current_user.reviews.find_by(id: params[:id])
    unless @review
      redirect_to reviews_path, alert: "他のユーザーのレビューは編集・削除できません。"
    end
  end

  def filter_reviews(reviews)
    return reviews unless params[:filter_type].present?

    case params[:filter_type]
    when /^category_(\d+)$/
      reviews.joins(:item).where(items: { category_id: $1.to_i })
    when "releasable"
      reviews.releasable
    else
      reviews
    end
  end

  # レビューに関連付けられた商品に画像(1枚目)を添付する
  def attach_image_to_item_if_needed
    if @review.item.images.blank? && @review.images.attached?
      @review.item.images.attach(@review.images.first.blob)
    end
  end

  # レビューの画像を削除する
  def handle_image_removal
    if params[:remove_images].present?
      params[:remove_images].split(",").each do |image_id|
        image = @review.images.find_by(id: image_id)
        image.purge if image
      end
    end
  end
end
