class ReleasableItem < ApplicationRecord
  belongs_to :review
  validates :name, length: { maximum: 50 }
end
