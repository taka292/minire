class Review < ApplicationRecord
  belongs_to :user
  has_many :releasable_items, dependent: :destroy
  # バリデーション
  validates :title, presence: true
  validates :content, presence: true

  # accepts_nested_attributes_for :releasable_items, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? }
  accepts_nested_attributes_for :releasable_items, allow_destroy: true

  # 空欄の手放せるものは保存前に削除
  before_save :mark_empty_items_for_destruction

  private

  # 空白は親要素を保存するタイミングで子モデルをまとめて削除
  def mark_empty_items_for_destruction
    releasable_items.each do |item|
      item.mark_for_destruction if item.name.blank?
    end
  end
end
