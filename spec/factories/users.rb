FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    name { "テストユーザー" }
    admin { false }

    trait :sns_user do
      provider { "google_oauth2" }
      uid { SecureRandom.uuid }
    end
  end
end
