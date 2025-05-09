class Category < ApplicationRecord
  has_many :items
  validates :name, presence: true, uniqueness: true

  # 並び順の設定
  acts_as_list

  scope :ordered, -> { order(:position) }

  def self.default
    find_by(name: "その他")
  end
end
