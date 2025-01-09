class AddCategoryIdToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :category_id, :integer, null: false
    add_foreign_key :reviews, :categories
    add_index :reviews, :category_id
  end
end
