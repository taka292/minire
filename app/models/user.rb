class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :reviews, dependent: :destroy
  has_one_attached :avatar
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_reviews, through: :likes, source: :review

  # 名前の長さは50文字以内
  validates :name, presence: true, length: { maximum: 50 }
  # 自己紹介文の長さは500文字以内
  validates :introduction, length: { maximum: 500 }, allow_blank: true
  validate :avatar_content_type
  validate :avatar_size

  def avatar_content_type
    allowed_types = %w[image/jpeg image/png image/gif]
    if avatar.attached? && !avatar.content_type.in?(allowed_types)
      errors.add(:avatar, "ファイル形式はJPEG, PNG, GIFのみアップロード可能です。")
    end
  end

  def avatar_size
    if avatar.attached? && avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "：5MB以下のファイルをアップロードしてください。")
    end
  end

  # リサイズした画像を返すメソッド
  def resized_avatar
    return unless avatar.attached? && avatar.blob.present?
    avatar.variant(resize_to_fill: [ 100, 100 ]).processed
  end
end
