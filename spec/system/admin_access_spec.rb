require 'rails_helper'

RSpec.describe "管理者アクセス", type: :system do
  let!(:admin_user) { create(:user, email: "admin@example.com", password: "password", admin: true) }
  let!(:general_user) { create(:user, email: "user@example.com", password: "password") }

  def log_in(email:, password:)
    visit new_user_session_path
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    click_button "ログイン"
  end

  it "管理者ユーザーはヘッダーに管理画面リンクが表示される" do
    log_in(email: admin_user.email, password: admin_user.password)
    expect(page).to have_content("ログインしました")

    expect(page).to have_selector("a[title='管理画面']")
  end

  it "一般ユーザーには管理画面リンクが表示されない" do
    log_in(email: general_user.email, password: general_user.password)
    expect(page).to have_content("ログインしました")

    expect(page).not_to have_selector("a[title='管理画面']")
  end

  it "未ログイン状態では管理画面リンクは表示されない" do
    visit root_path
    expect(page).not_to have_selector("a[title='管理画面']")
  end

  it "管理者ユーザーは管理画面にアクセスできる" do
    log_in(email: admin_user.email, password: admin_user.password)

    visit admin_items_path
    expect(page).to have_content("アイテム")
  end

  it "一般ユーザーが管理画面にアクセスするとリダイレクトされる" do
    log_in(email: general_user.email, password: general_user.password)
    expect(page).to have_content("ログインしました")

    visit admin_items_path
    expect(current_path).to eq root_path
    expect(page).to have_content("管理者権限が必要です")
  end
end
