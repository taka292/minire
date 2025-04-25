class Review < ApplicationRecord
  belongs_to :user
  belongs_to :item
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # バリデーション
  validates :title, presence: true, length: { maximum: 100, message: "100文字以内で入力してください" }
  validates :content, presence: true, length: { maximum: 1000, message: "1000文字以内で入力してください" }

  has_many_attached :images

  has_many :likes, dependent: :destroy
  validate :image_content_type
  validate :image_size
  validate :image_count_within_limit

  # 絞り込み条件
  # カテゴリ絞り込みスコープ
  scope :by_category, ->(category_id) {
    joins(:item).where(items: { category_id: category_id }) if category_id.present?
  }


  # 手放せるものの絞り込みスコープ (EXISTS クエリを使用)
  scope :releasable, -> {
    where("EXISTS (SELECT 1 FROM releasable_items WHERE releasable_items.review_id = reviews.id)")
  }

  # 並び替え
  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :with_likes_count, -> {
    left_joins(:likes)
      .select("reviews.*, COUNT(likes.id) AS likes_count")
      .group("reviews.id")
  }

  scope :sort_by_most_liked, -> {
    with_likes_count.order(Arel.sql("likes_count DESC NULLS LAST"))
  }

  def self.apply_sort(sort_param)
    case sort_param
    when "newest" then sort_by_newest
    when "oldest" then sort_by_oldest
    when "highest_rating" then sort_by_highest_rating
    when "lowest_rating" then sort_by_lowest_rating
    when "most_liked" then sort_by_most_liked
    else sort_by_newest # デフォルト
    end
  end


  # ファイル形式のバリデーション
  def image_content_type
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png image/gif])
        errors.add(:images, "JPEG, PNG, GIF形式のみアップロードできます")
      end
    end
  end

  # ファイルサイズのバリデーション
  def image_size
    return unless images.attached?

    images.each do |image|
      if image.blob.byte_size > 5.megabytes
        errors.add(:images, "5MB以下のファイルをアップロードしてください")
      end
    end
  end

  # レビュー画像のリサイズ処理
  def resized_images
    images.map do |image|
      image.variant(resize_to_fill: [ 200, 200 ]).processed
    end
  end

  def image_count_within_limit
    if images.size > 5
      errors.add(:images, "5枚以下でアップロードしてください")
    end
  end

  has_many :releasable_items, dependent: :destroy

  accepts_nested_attributes_for :releasable_items, allow_destroy: true

  # 空欄の手放せるものは保存前に削除
  before_save :mark_empty_items_for_destruction

  def self.search(query)
    return all if query.blank?

    left_outer_joins(:item, :releasable_items).where(
      "items.name ILIKE :query OR reviews.title ILIKE :query OR reviews.content ILIKE :query ",
      query: "%#{query}%"
    ).distinct
  end

 # reviewへのいいね通知機能
 def create_notification_favorite_review!(current_user)
   # 同じユーザーが同じ投稿に既にいいねしていないかを確認
   existing_notification = Notification.find_by(review_id: self.id, visitor_id: current_user.id, action: "favorite_review")

   # すでにいいねされていない場合のみ通知レコードを作成
   if existing_notification.nil? && current_user != self.user
     notification = Notification.new(
       review_id: self.id,
       visitor_id: current_user.id,
       visited_id: self.user.id,
       action: "favorite_review"
     )

     if notification.valid?
       notification.save
     end
   end
 end

  # コメントが投稿された際に通知を作成するメソッド
  def create_notification_comment!(current_user, comment_id)
    # 自分以外にコメントしている人をすべて取得し、全員に通知を送る
    other_commenters_ids = Comment.select(:user_id).where(review_id: id).where.not(user_id: current_user.id).distinct.pluck(:user_id)

    # 各コメントユーザーに対して通知を作成
    other_commenters_ids.each do |commenter_id|
      save_notification_comment!(current_user, comment_id, commenter_id)
    end

    # まだ誰もコメントしていない場合は、投稿者に通知を送る
    save_notification_comment!(current_user, comment_id, user_id) if other_commenters_ids.blank?
  end

  # 通知を保存するメソッド
  def save_notification_comment!(current_user, comment_id, visited_id)
    notification = current_user.active_notifications.build(
      review_id: id,
      comment_id: comment_id,
      visited_id: visited_id,
      action: "comment"
    )

    # 自分の投稿に対するコメントの場合は、通知済みとする
    notification.checked = true if notification.visitor_id == notification.visited_id

    # 通知を保存（バリデーションが成功する場合のみ）
    notification.save if notification.valid?
  end

  # 商品情報をパラメータに基づいて取得・作成し、レビューに関連付ける
  # 処理失敗時はエラーを追加して false を返す
  def assign_item_by_params(params)
    item =
      case params[:search_method] # Amazonまたはサイト内検索に応じてItemを取得・登録
      when "amazon" # Amazon検索(デフォルト)
        asin = params[:asin]&.strip                    # Amazonの商品コード（ASIN）
        item_name = params[:amazon_item_name]&.strip  # Amazon検索候補で選択された商品名

        # Amazonの商品が選択されていない場合はエラー
        if asin.blank? || item_name.blank?
          return error!(:amazon_item_name, "Amazonの商品を選択してください")
        end

        # ASINをもとに、商品登録または取得
        fetched_item = fetch_amazon_info_if_needed(Item.find_or_initialize_by(asin: asin))

        # 取得した商品に名前がない場合はエラー（取得失敗とみなす）
        if fetched_item.name.blank?
          return error!(:amazon_item_name, "商品情報の取得に失敗しました。もう一度お試しください")
        end

        fetched_item

      when "minire" # サイト内商品検索・登録(商品が見つからない場合)
        item_name = params[:item_name]&.strip  # サイト内検索で指定された商品名

        if item_name.blank?
          return error!(:item_name, "商品名を入力してください")
        end

        # 名前から商品を作成し、カテゴリ未設定であれば「その他」にする
        Item.find_or_initialize_by(name: item_name).tap do |i|
          i.category ||= Category.find_by(name: "その他")
        end

      else
        # 想定外の search_method の場合もエラー
        return error!(:item_name, "商品名を入力してください")
      end

    unless item.save
      return error!(:item_name, item.errors.full_messages.join(", "))
    end

    # 商品をレビューに関連付け
    self.item = item
    true
  end

  private

  # 空白は親要素を保存するタイミングで子モデルをまとめて削除
  def mark_empty_items_for_destruction
    releasable_items.each do |item|
      item.mark_for_destruction if item.name.blank?
    end
  end

  # Amazon検索で取得したasinのItemが登録されていない場合のみ、Amazon APIから商品情報取得
  def fetch_amazon_info_if_needed(item)
    if item.asin.present? && item.last_updated_at.blank?
      imported_item = AmazonItemImporter.new(item.asin).import!
      return imported_item || item
    end
    # 既に登録済みであればDBから取得した情報を返す
    item
  end

  # エラーを追加し、false を返す簡易メソッド
  def error!(attr, message)
    self.errors.add(attr, message)
    false
  end
end
