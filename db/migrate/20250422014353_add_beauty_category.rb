class AddBeautyCategory < ActiveRecord::Migration[7.2]
  def up
    Category.find_or_create_by!(name: "ビューティー")
  end

  def down
    Category.find_by(name: "ビューティー")&.destroy
  end
end
