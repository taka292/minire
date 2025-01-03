class AddItemsToReviews < ActiveRecord::Migration[7.2]
  def change
    add_reference :reviews, :item, foreign_key: true
    #  ,null: false,
  end
end
