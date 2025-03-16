class Review < ApplicationRecord
  belongs_to :user
  belongs_to :item
  belongs_to :category
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
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }

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

  # accepts_nested_attributes_for :releasable_items, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? }
  accepts_nested_attributes_for :releasable_items, allow_destroy: true

  # 空欄の手放せるものは保存前に削除
  before_save :mark_empty_items_for_destruction

  def self.search(query)
    return all if query.blank?

    joins(:item, :category, :releasable_items).where(
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

  private

  # 空白は親要素を保存するタイミングで子モデルをまとめて削除
  def mark_empty_items_for_destruction
    releasable_items.each do |item|
      item.mark_for_destruction if item.name.blank?
    end
  end
end
