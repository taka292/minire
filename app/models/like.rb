class Like < ApplicationRecord
  belongs_to :user
  belongs_to :review

  validates :user_id, uniqueness: { scope: :review_id, message: "同じレビューに2回以上いいねできません" }
end
