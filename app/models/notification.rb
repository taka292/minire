class Notification < ApplicationRecord
  belongs_to :visitor, class_name: "User"
  belongs_to :visited, class_name: "User"
  belongs_to :review, optional: true
  belongs_to :comment, optional: true

  validates :visitor_id, :visited_id, :action, presence: true
  validates :comment_id, presence: true, if: -> { action == "comment" }
end
