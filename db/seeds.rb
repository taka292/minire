# カテゴリの作成
categories = %w[日用品 衣類 ガジェット・家電 キッチン用品 食料品 趣味 その他]
categories.each do |category_name|
  Category.find_or_create_by!(name: category_name)
end
puts "Categories created."

# ユーザーの作成
users = 5.times.map do |i|
  User.find_or_create_by!(email: "user#{i + 1}@example.com") do |user|
    user.name = "User #{i + 1}"
    user.password = "password"
    user.confirmed_at = Time.now # Confirmable対応
  end
end
puts "Users created."

# アイテムの作成
items = 10.times.map do |i|
  Item.find_or_create_by!(name: "Item #{i + 1}") do |item|
    item.price = "#{rand(100..1000)}円"
    item.manufacturer = "メーカー #{i + 1}"
    item.amazon_url = "https://www.amazon.co.jp/dp/#{SecureRandom.hex(5)}"
  end
end
puts "Items created."

# レビューの作成
reviews = 20.times.map do
  user = users.sample
  category = Category.order("RANDOM()").first
  item = items.sample

  Review.create!(
    user: user,
    title: "#{category.name}のおすすめ商品",
    content: "これは素晴らしい商品です！特に#{category.name}において非常に役立ちます。",
    category: category,
    item: item,
    created_at: rand(1..30).days.ago
  )
end
puts "Reviews created."

# 手放せるアイテムの作成
reviews.sample(10).each do |review|
  rand(1..3).times do
    review.releasable_items.create!(
      name: "手放せるアイテム #{SecureRandom.hex(3)}"
    )
  end
end
puts "Releasable items created."
