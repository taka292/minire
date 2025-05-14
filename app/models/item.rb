class Item < ApplicationRecord
  has_many :reviews
  has_many_attached :images
  belongs_to :category, optional: true  # カテゴリが未設定の既存Itemに対応

  validates :name, presence: true, uniqueness: { case_sensitive: false } # 空文字を許可せず、大文字小文字を区別せず、一意性を保証。
  validates :name, length: { minimum: 1 }
  validates :amazon_url, format: { with: URI.regexp(%w[http https]), message: "正しいURL形式を入力してください。" }, allow_blank: true
  validate :image_content_type
  validates :description, length: { maximum: 1000 }, allow_blank: true

  before_validation :set_default_category

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

  # カテゴリのデフォルト値(その他)を設定するメソッド
  def set_default_category
    self.category ||= Category.default
  end

  # 検索機能の実装
  def self.ransackable_attributes(auth_object = nil)
    %w[
      name
      description
      asin
      manufacturer
    ]
  end
end
