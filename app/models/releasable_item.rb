class ReleasableItem < ApplicationRecord
  belongs_to :review
  validates :name, length: { maximum: 50 }

  def self.ransackable_attributes(auth_object = nil)
    %w[
      name
    ]
  end
end
