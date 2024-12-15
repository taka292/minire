class ReleasableItem < ApplicationRecord
  belongs_to :review
  # 空白の入力は無視
  # validates :name, presence: true
end
