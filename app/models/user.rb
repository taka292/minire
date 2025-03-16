class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  has_many :reviews, dependent: :destroy
  has_one_attached :avatar
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_reviews, through: :likes, source: :review
  # 自分からの通知
  has_many :active_notifications, class_name: 'Notification', foreign_key: 'visitor_id', dependent: :destroy
  # 相手からの通知
  has_many :passive_notifications, class_name: 'Notification', foreign_key: 'visited_id', dependent: :destroy

  # 名前の長さは50文字以内
  validates :name, presence: true, length: { maximum: 50 }
  # 自己紹介文の長さは500文字以内
  validates :introduction, length: { maximum: 500 }, allow_blank: true
  validate :avatar_content_type
  validate :avatar_size

  # 新規登録時に自動で確認済みにする
  after_create :auto_confirm_account

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

  def auto_confirm_account
    return if confirmed?

    self.update_columns(confirmed_at: Time.current) # 明示的に確認済み状態に設定
  end

  def admin?
    self.admin
  end
end
