class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user
  has_many :notifications, dependent: :destroy

  validates :content, presence: true, length: { maximum: 300 }
end
