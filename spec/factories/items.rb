FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "ミニマリスト用テーブル#{n}" }
    price { "3000" }
    manufacturer { "abc株式会社" }
    amazon_url { "https://www.amazon.co.jp/dp/B08XYZ1234" }
    sequence(:asin) { |n| "ASIN#{n}" }
    last_updated_at { "2025-01-01 11:15:06" }
  end
end
