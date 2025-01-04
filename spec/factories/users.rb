FactoryBot.define do
  factory :user do
    email { "test@example.com" }
    password { "password" }
    password_confirmation { "password" }
    name { "テストユーザー" }
    admin { false }
  end
end
