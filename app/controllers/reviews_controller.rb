class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_review, only: %i[edit update destroy]

  def new
    @review = Review.new
  end

  def create
    @review = current_user.reviews.build(review_params)

    result = ActiveRecord::Base.transaction do
      unless assign_item_to_review
        raise ActiveRecord::Rollback
      end

      if @review.save
        attach_image_to_item_if_needed
        redirect_to reviews_path, notice: "レビューを投稿しました！"
      else
        raise ActiveRecord::Rollback
      end
    end

    render :new, status: :unprocessable_entity unless result
  end


  def show
    @review = Review.find(params[:id])
    @comments = @review.comments.includes(:user)
    @comment = @review.comments.new
  end

  def index
    @query = params[:query]

    if params[:sort] == "most_liked"
      @reviews = Review.with_likes_count
    else
      @reviews = Review.includes(:user, :item, :comments, images_attachments: :blob)
    end

    @categories = Category.all

    # 絞り込み処理
    if params[:filter_type].present?
      @reviews = case params[:filter_type]
      when /^category_(\d+)$/
        reviews = @reviews.joins(:item).where(items: { category_id: $1.to_i })
      when "releasable"
        @reviews.releasable
      else
        @reviews
      end
    end

    # 検索条件を適用
    @reviews = @reviews.search(@query)

    # 並び替え
    @reviews = @reviews.apply_sort(params[:sort])


    # ページネーション
    @reviews = @reviews.order(created_at: :desc).page(params[:page])
  end

  def edit
  end

  def update
    result = ActiveRecord::Base.transaction do
      unless assign_item_to_review
        raise ActiveRecord::Rollback
      end

      handle_image_removal
      @review.images.attach(params[:review][:images]) if params[:review][:images].present?

      if @review.update(review_params.except(:images))
        # attach_image_to_item_if_needed # 画像をitemに添付処理はリファクタリングとは別で対応
        redirect_to @review, notice: "レビューを更新しました！"
      else
        raise ActiveRecord::Rollback
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
    params.require(:review).permit(:title, :content, :category_id, images: [], releasable_items_attributes: [ :id, :name, :_destroy ])
  end

  def set_review
    @review = current_user.reviews.find_by(id: params[:id])
    unless @review
      redirect_to reviews_path, alert: "他のユーザーのレビューは編集・削除できません。"
    end
  end

  # Amazon検索で取得したItemがまだ詳細情報を持っていない場合のみ、Amazon APIから取得して補完する
  def fetch_amazon_info_if_needed(item)
    if item.asin.present? && item.last_updated_at.blank?
      imported_item = AmazonItemImporter.new(item.asin).import!
      return imported_item if imported_item.present?
    end
    item
  end

  # 商品をレビューに関連付ける
  def assign_item_to_review
    # Amazonまたはサイト内検索に応じてItemを取得・登録し、レビューに関連付ける
    case params[:search_method]
    when "amazon"  # Amazon商品検索・登録(デフォルト)
      asin = params[:asin]&.strip # Amazonの商品コード
      item_name = params[:amazon_item_name]&.strip # Amazon商品名

      if asin.blank? || item_name.blank?
        @review.errors.add(:amazon_item_name, "Amazonの商品を選択してください")
        return false
      end

      item = fetch_amazon_info_if_needed(Item.find_or_initialize_by(asin: asin))

      if item.name.blank?
        @review.errors.add(:amazon_item_name, "商品情報の取得に失敗しました。もう一度お試しください")
        return false
      end

    when "minire" # サイト内商品検索・登録(商品が見つからない場合)
      item_name = params[:item_name]&.strip

      if item_name.blank?
        @review.errors.add(:item_name, "商品名を入力してください")
        return false
      end

      item = Item.find_or_initialize_by(name: item_name)
      item.category ||= Category.find_by(name: "その他")

    else
      @review.errors.add(:item_name, "商品名を入力してください")
      return false
    end

    unless item.save
      @review.errors.add(:item_name, item.errors.full_messages.join(", "))
      return false
    end

    @review.item = item
    true
  end

  # レビューに関連付けられた商品に画像(1枚目)を添付する
  def attach_image_to_item_if_needed
    if @review.item.images.blank? && @review.images.attached?
      @review.item.images.attach(@review.images.first.blob)
    end
  end

  # レビューの画像を削除する
  def handle_image_removal
    if params[:review][:remove_images].present?
      params[:review][:remove_images].split(",").each do |image_id|
        image = @review.images.find_by(id: image_id)
        image.purge if image
      end
    end
  end
end
