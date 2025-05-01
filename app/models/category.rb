class Category < ApplicationRecord
  has_many :items
  validates :name, presence: true, uniqueness: true

  def self.default
    find_by(name: "その他")
  end
end
