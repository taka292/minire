class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :reviews, dependent: :destroy
  has_one_attached :avatar

  # バリデーション
  validates :name, presence: true
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
    avatar.variant(resize_to_fill: [ 100, 100 ]).processed
  end
end
