class ChangeNameToTextInItems < ActiveRecord::Migration[7.0]
  def change
    change_column :items, :name, :text
  end
end
