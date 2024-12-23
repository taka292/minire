FactoryBot.define do
  factory :comment do
    content { "MyString" }
    review { nil }
    user { nil }
  end
end
