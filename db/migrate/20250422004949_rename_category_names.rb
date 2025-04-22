class RenameCategoryNames < ActiveRecord::Migration[7.2]
  def change
    Category.find_by(name: "キッチン用品")&.update(name: "ホーム＆キッチン")
    Category.find_by(name: "衣類")&.update(name: "衣類・小物")
  end
end
