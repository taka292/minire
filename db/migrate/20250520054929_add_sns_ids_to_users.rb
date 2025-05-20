class AddSnsIdsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :instagram_id, :string
    add_column :users, :x_id, :string
    add_column :users, :youtube_id, :string
    add_column :users, :note_id, :string
  end
end
