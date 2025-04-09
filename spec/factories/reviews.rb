FactoryBot.define do
  factory :review do
    title { "テストタイトル" }
    content { "テスト内容" }
    association :user
    association :item
    association :category
  end

  trait :with_images do
    after(:build) do |review|
      review.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/sample1.jpg")),
        filename: "sample1.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
