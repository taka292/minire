class RemoveCategoryIdFromReviews < ActiveRecord::Migration[7.2]
  def change
    remove_column :reviews, :category_id, :integer
  end
end
