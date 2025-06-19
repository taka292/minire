class AddStatusToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :status, :integer, null: false, default: 0
  end
end
