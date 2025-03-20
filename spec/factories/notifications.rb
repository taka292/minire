FactoryBot.define do
  factory :notification do
    association :visitor, factory: :user
    association :visited, factory: :user
    action { "like" }
    checked { false }

    trait :for_like do
      association :review
      comment { nil }
      action { "like" }
    end

    trait :for_comment do
      association :comment
      review { nil }
      action { "comment" }
    end
  end
end
