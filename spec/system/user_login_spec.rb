require 'rails_helper'

RSpec.describe "ユーザー認証", type: :system do
  let!(:user) do
    create(:user, email: "test@example.com", password: "password")
  end

  it "正しい情報でログインできる" do
    visit new_user_session_path

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: user.password
    click_button "ログイン"

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_content("ログイン")
  end

    it "間違ったパスワードではログインに失敗する" do
    visit new_user_session_path

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "wrongpassword"
    click_button "ログイン"

    expect(page).to have_content("メールアドレスまたはパスワードが正しくありません。")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "ログイン後にログアウトできる" do
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: user.password
    click_button "ログイン"

    click_link "ログアウト", match: :first
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("ログアウトしました").or have_content("ログイン")
  end

  it "未ログイン状態で保護ページにアクセスするとログイン画面にリダイレクトされる" do
    visit profile_path(user.id) # ←修正ポイント！

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("ログイン")
  end

  it "ログイン後にマイページにアクセスできる" do
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: user.password
    click_button "ログイン"

    visit profile_path(user.id)
    expect(page).to have_current_path(profile_path(user.id))
    expect(page).to have_content(user.name)
  end
end
