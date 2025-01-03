class Item < ApplicationRecord
  has_many :reviews
  # 空文字を許可せず、大文字小文字を区別せず、一意性を保証。
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { minimum: 1, maximum: 50 }

  # # 商品名で検索し、存在しなければ作成
  # def self.find_or_create_by_name(name)
  #   sanitized_name = name.strip # 前後の空白を削除
  #   item = find_or_initialize_by(name: sanitized_name) #商品を検索または新規作成
  #   item.save if item.new_record? # 商品が新規の場合のみ保存
  #   item
  # end
end
