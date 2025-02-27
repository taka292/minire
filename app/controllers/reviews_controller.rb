class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_review, only: %i[edit update destroy]

  def new
    @review = Review.new
    # レビューの新規作成時に、手放せるものリストのフォームを3つ表示
    3.times { @review.releasable_items.build }
  end

  def create
    result = ActiveRecord::Base.transaction do
      # レビューを初期化
      @review = current_user.reviews.build(review_params)

      # 商品名が空の場合のエラーハンドリング
      if params[:item_name].blank?
        @review.errors.add(:item_name, "商品名を入力してください")
        raise ActiveRecord::Rollback
      end

      # 商品を検索または作成
      item_name = params[:item_name].strip
      # 商品名を指定して初めの1件を取得し1件もなければ作成
      item = Item.find_or_initialize_by(name: item_name)
      unless item.save
        @review.errors.add(:item_name, item.errors.full_messages.join(", "))
        raise ActiveRecord::Rollback
      end

      # 商品を関連付けてレビューを保存
      @review.item = item
      if @review.save
        redirect_to reviews_path, notice: "レビューを投稿しました！"
      else
        raise ActiveRecord::Rollback
      end
    end
  unless result
    render :new, status: :unprocessable_entity
  end
end


  def show
    @review = Review.find(params[:id])
    @comments = @review.comments.includes(:user)
    @comment = @review.comments.new
  end

  def index
    @query = params[:query]
    @reviews = Review.all

    # 絞り込み処理
    if params[:filter_type].present?
      @reviews = case params[:filter_type]
      when /^category_(\d+)$/
        @reviews.by_category($1.to_i)
      when "releasable"
        @reviews.releasable
      else
        @reviews
      end
    end

    # 検索条件を適用
    @reviews = @reviews.search(@query)

    # ページネーション
    @reviews = @reviews.order(created_at: :desc).page(params[:page])
  end

  def edit
      @review = current_user.reviews.find(params[:id])
      # 登録している手放せるものを差し引いた、空のフォームを追加
      remaining_slots = [ 3 - @review.releasable_items.size, 0 ].max
      remaining_slots.times { @review.releasable_items.build }
  end

  def update
    result = ActiveRecord::Base.transaction do
      # 商品を検索または作成
      item_name = params[:item_name]&.strip
      if item_name.blank?
        @review.errors.add(:item_name, "商品名を入力してください")
        raise ActiveRecord::Rollback
      end

      # 商品名を指定して初めの1件を取得し1件もなければ作成
      item = Item.find_or_initialize_by(name: item_name)
      unless item.save
        @review.errors.add(:item_name, item.errors.full_messages.join(", "))
        raise ActiveRecord::Rollback
      end

      # 商品を関連付けてレビューを更新
      @review.item = item

      # 削除対象の画像を削除
      if params[:review][:remove_images].present?
        params[:review][:remove_images].split(",").each do |image_id|
          image = @review.images.find_by(id: image_id)
          image.purge if image
        end
      end

      # 新しい画像を添付
      @review.images.attach(params[:review][:images]) if params[:review][:images].present?

      # 他のレビュー情報を更新
      if @review.update(review_params.except(:images))
        redirect_to @review, notice: "レビューを更新しました！"
      else
        raise ActiveRecord::Rollback
      end
    end
  unless result
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
    params.require(:review).permit(:title, :content, :category_id, images: [], releasable_items_attributes: [ :id, :name, :_destroy ])
  end

  def set_review
    @review = current_user.reviews.find_by(id: params[:id])
    unless @review
      redirect_to reviews_path, alert: "他のユーザーのレビューは編集・削除できません。"
    end
  end
end
