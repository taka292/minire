class CreateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.string :price
      t.string :manufacturer
      t.string :amazon_url
      t.string :asin
      t.datetime :last_updated_at

      t.timestamps
    end
  end
end
