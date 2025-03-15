class Notification < ApplicationRecord
  belongs_to :visitor
  belongs_to :visited
  belongs_to :review
  belongs_to :comment
end
