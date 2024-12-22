FactoryBot.define do
  factory :review do
    title { "テストタイトル" }
    content { "テスト内容" }
    association :user
  end
end
