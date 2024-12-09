class ReleasableItem < ApplicationRecord
  belongs_to :review
  # validates :name, presence: true
end
