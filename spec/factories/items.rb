FactoryBot.define do
  factory :item do
    name { "ミニマリスト用テーブル" }
    price { "3000" }
    manufacturer { "abc株式会社" }
    amazon_url { "https://www.amazon.co.jp/dp/B08XYZ1234" }
    asin { "12345-890" }
    last_updated_at { "2025-01-01 11:15:06" }
  end
end
