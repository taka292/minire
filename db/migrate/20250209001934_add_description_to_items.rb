class AddDescriptionToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :description, :text
  end
end
