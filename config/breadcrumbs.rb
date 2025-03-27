# config/breadcrumbs.rb

crumb :root do
  link "ホーム", root_path
end

# Devise関連
crumb :sign_in do
  link "ログイン", new_user_session_path
  parent :root
end

crumb :sign_up do
  link "新規登録", new_user_registration_path
  parent :root
end

crumb :password_new do
  link "パスワードを忘れた方", new_user_password_path
  parent :sign_in
end

crumb :password_edit do
  link "パスワード再設定", edit_user_password_path
  parent :sign_in
end

crumb :reviews do
  link "レビュー 一覧", reviews_path
  parent :root
end

crumb :review do |review|
  link review.title, review_path(review)
  parent :reviews
end

crumb :new_review do
  link "新しいレビュー", new_review_path
  parent :reviews
end

crumb :edit_review do |review|
  link "レビュー編集", edit_review_path(review)
  parent :review, review
end

crumb :item do |item|
  link item.name, item_path(item)
  parent :reviews
end

crumb :profile do |user|
  link "#{user.name}さんのプロフィール", profile_path(user)
  parent :root
end

crumb :edit_profile do |user|
  link "プロフィール編集", edit_profile_path(user)
  parent :profile, user
end

crumb :likes do |user|
  link "いいねした投稿", likes_profile_path(user)
  parent :profile, user
end

crumb :edit_email do |user|
  link "メールアドレス変更", edit_email_profile_path(user)
  parent :edit_profile, user
end

crumb :edit_password do |user|
  link "パスワード変更", edit_password_profile_path(user)
  parent :edit_profile, user
end

crumb :terms_of_service do
  link "利用規約", terms_of_service_path
  parent :root
end

crumb :privacy_policy do
  link "プライバシーポリシー", privacy_policy_path
  parent :root
end

# 管理者用
crumb :admin_items do
  link "管理画面 - アイテム一覧", admin_items_path
  parent :root
end

crumb :edit_admin_item do |item|
  link "アイテム編集", edit_admin_item_path(item)
  parent :admin_items
end
