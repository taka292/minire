class Review < ApplicationRecord
  belongs_to :user
  has_many :releasable_items, dependent: :destroy
  # バリデーション
  validates :title, presence: true
  validates :content, presence: true

  accepts_nested_attributes_for :releasable_items
  # 手放せるものリストの削除機能時には下記に修正
  # accepts_nested_attributes_for :releasable_items, allow_destroy: true
end
