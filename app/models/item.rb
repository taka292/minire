class Item < ApplicationRecord
  has_many :reviews
  has_many_attached :images
  # 空文字を許可せず、大文字小文字を区別せず、一意性を保証。
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { minimum: 1 }
  validates :amazon_url, format: { with: URI.regexp(%w[http https]), message: "正しいURL形式を入力してください。" }, allow_blank: true
  validate :image_content_type
  validates :description, length: { maximum: 1000 }, allow_blank: true

  # ファイル形式のバリデーション
  def image_content_type
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png])
        errors.add(:images, "JPEG, PNGのみアップロードできます")
      end
    end
  end

  # レビュー画像のリサイズ処理
  def resized_images
    images.map do |image|
      image.variant(resize_to_fill: [ 100, 100 ]).processed
    end
  end
end
