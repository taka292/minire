class CreateReleasableItems < ActiveRecord::Migration[7.2]
  def change
    create_table :releasable_items do |t|
      t.references :review, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
