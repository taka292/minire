class AddPositionToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :position, :integer

    # カテゴリの並び順（position）を初期化
    Category.order(:id).each.with_index do |category, index|
      category.update_column(:position, index)
    end

    add_index :categories, :position
  end
end
