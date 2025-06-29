class Review < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :item
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :releasable_items, dependent: :destroy

  # 画像の添付
  has_many_attached :images

  # ネストされたフォーム
  accepts_nested_attributes_for :releasable_items, allow_destroy: true

  # コールバック
  before_save :mark_empty_items_for_destruction

  # バリデーション
  validates :title, presence: true, length: { maximum: 100, message: "100文字以内で入力してください" }
  validates :content, presence: true, length: { maximum: 1000, message: "1000文字以内で入力してください" }
  validate :image_content_type
  validate :image_size
  validate :image_count_within_limit

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
      .includes_for_index
      .select("reviews.*, COUNT(likes.id) AS likes_count")
      .group("reviews.id")
  }
  scope :sort_by_most_liked, -> {
    with_likes_count.order("likes_count DESC NULLS LAST")
  }

  # 一覧表示用のincludes
  scope :includes_for_index, -> {
    includes(
      :comments,
      :likes,
      { images_attachments: :blob },
      { item: { images_attachments: :blob } },
      { user: { avatar_attachment: :blob } }
    )
  }

  # レビューの下書き・公開状態
  enum :status, { published: 0, draft: 1 }

  # ソートパラメータを適用するクラスメソッド
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

  # 検索機能で使用するカラムの定義
  def self.ransackable_attributes(auth_object = nil)
    %w[title content]
  end

  # 検索機能で使用する関連モデルの定義
  def self.ransackable_associations(auth_object = nil)
    %w[item releasable_items]
  end

  # レビュー画像のリサイズ処理
  def resized_images
    images.map do |image|
      image.variant(resize_to_fill: [ 200, 200 ]).processed
    end
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

  private

  # 空白は親要素を保存するタイミングで子モデルをまとめて削除
  def mark_empty_items_for_destruction
    releasable_items.each do |item|
      item.mark_for_destruction if item.name.blank?
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

  # ファイル枚数のバリデーション
  def image_count_within_limit
    if images.size > 5
      errors.add(:images, "5枚以下でアップロードしてください")
    end
  end
end
