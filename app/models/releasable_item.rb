class ReleasableItem < ApplicationRecord
  belongs_to :review
  # 空白の入力は無視
  # validates :name, presence: true
  validates :name, length: { maximum: 50 }
end
