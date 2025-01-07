class Review < ApplicationRecord
  belongs_to :user
  has_many :releasable_items, dependent: :destroy
  has_many :comments, dependent: :destroy
  belongs_to :category

  # バリデーション
  validates :title, presence: true, length: { maximum: 100, message: "100文字以内で入力してください" }
  validates :content, presence: true, length: { maximum: 1000, message: "1000文字以内で入力してください" }
  # validates :category_id, presence: { message: "カテゴリを選択してください" }

  # accepts_nested_attributes_for :releasable_items, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? }
  accepts_nested_attributes_for :releasable_items, allow_destroy: true

  # 空欄の手放せるものは保存前に削除
  before_save :mark_empty_items_for_destruction

  has_many_attached :images
  has_many :likes, dependent: :destroy
  validate :image_content_type
  validate :image_size
  validate :image_count_within_limit
  belongs_to :item

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

  private

  # 空白は親要素を保存するタイミングで子モデルをまとめて削除
  def mark_empty_items_for_destruction
    releasable_items.each do |item|
      item.mark_for_destruction if item.name.blank?
    end
  end
end
