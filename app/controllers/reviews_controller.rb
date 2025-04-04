class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_review, only: %i[edit update destroy]

  def new
    @review = Review.new
    # レビューの新規作成時に、手放せるものリストのフォームを3つ表示
    3.times { @review.releasable_items.build }
  end

  # AmazonAPIが一時的に使用できないため、暫定で下記で実装
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
        # 該当商品の画像が空の場合、レビューの画像1枚目を商品に添付
        if item.images.blank? && @review.images.attached?
          item.images.attach(@review.images.first.blob)
        end

        redirect_to reviews_path, notice: "レビューを投稿しました！"
      else
        raise ActiveRecord::Rollback
      end
    end

    unless result
      render :new, status: :unprocessable_entity
    end
  end

  # AmazonAPIが一時的に使用できないため、暫定でコメントアウト(使用可能になり次第、editのコードもamzon検索対応要)
  #   def create
  #     result = ActiveRecord::Base.transaction do
  #       @review = current_user.reviews.build(review_params)
  #
  #       case params[:search_method]
  #       when "amazon"
  #         asin = params[:asin]&.strip
  #         item_name = params[:amazon_item_name]&.strip
  #
  #         # ASINか商品名が空ならエラー(手入力した場合、asinが空になって弾く)
  #         if asin.blank? || item_name.blank?
  #           @review.errors.add(:amazon_item_name, "Amazonの商品を選択してください")
  #           raise ActiveRecord::Rollback
  #         end
  #
  #         item = Item.find_or_initialize_by(asin: asin) do |new_item|
  #           new_item.name = item_name
  #         end
  #
  #       when "minire"
  #         item_name = params[:item_name]&.strip
  #
  #         if item_name.blank?
  #           @review.errors.add(:item_name, "商品名を入力してください")
  #           raise ActiveRecord::Rollback
  #         end
  #
  #         item = Item.find_or_initialize_by(name: item_name)
  #
  #       else
  #         @review.errors.add(:item_name, "商品名を入力してください")
  #         raise ActiveRecord::Rollback
  #       end
  #
  #       unless item.save
  #         @review.errors.add(:item_name, item.errors.full_messages.join(", "))
  #         raise ActiveRecord::Rollback
  #       end
  #
  #       @review.item = item
  #       if @review.save
  #         if item.images.blank? && @review.images.attached?
  #           item.images.attach(@review.images.first.blob)
  #         end
  #
  #         redirect_to reviews_path, notice: "レビューを投稿しました！"
  #       else
  #         raise ActiveRecord::Rollback
  #       end
  #     end
  #
  #     unless result
  #       render :new, status: :unprocessable_entity
  #     end
  #   end



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
        @reviews.by_category($1.to_i)
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
      @review = current_user.reviews.find(params[:id])
      set_releasable_items
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
    set_releasable_items
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

  # 手放せるものフォームで、すでに登録されている数を確認し、足りない分だけフォームを追加
  def set_releasable_items
    remaining_slots = [ 3 - @review.releasable_items.size, 0 ].max
    remaining_slots.times { @review.releasable_items.build }
  end
end
