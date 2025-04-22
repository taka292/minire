class AddCategoryIdToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :category_id, :integer
    add_foreign_key :items, :categories
    add_index :items, :category_id
  end
end
