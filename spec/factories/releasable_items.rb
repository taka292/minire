FactoryBot.define do
  factory :releasable_item do
    name { "手放せるアイテム" }
    association :review
  end
end
