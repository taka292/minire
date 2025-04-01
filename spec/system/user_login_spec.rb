require 'rails_helper'

RSpec.describe "ユーザー認証", type: :system do
  let!(:user) { create(:user, email: "test@example.com", password: "password") }

  def log_in(email:, password:)
    visit new_user_session_path
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    click_button "ログイン"
  end

  it "正しい情報でログインできる" do
    log_in(email: user.email, password: user.password)

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_content("ログイン")
  end

  it "間違ったパスワードではログインに失敗する" do
    log_in(email: user.email, password: "wrongpassword")

    expect(page).to have_content("メールアドレスまたはパスワードが正しくありません。")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "ログイン後にログアウトできる" do
    log_in(email: user.email, password: user.password)

    click_link "ログアウト", match: :first
    expect(page).to have_content("ログアウトしました").or have_content("ログイン")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "未ログイン状態で保護ページにアクセスするとログイン画面にリダイレクトされる" do
    visit profile_path(user.id)

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("ログイン")
  end

  it "ログイン後にマイページにアクセスできる" do
    log_in(email: user.email, password: user.password)

    visit profile_path(user.id)
    expect(page).to have_current_path(profile_path(user.id))
    expect(page).to have_content(user.name)
  end

  it "新規ユーザー登録が成功する" do
    visit new_user_registration_path

    fill_in "user[name]", with: "新規テストユーザー"
    fill_in "user[email]", with: "newuser@example.com"
    fill_in "user[password]", with: "newpassword"
    fill_in "user[password_confirmation]", with: "newpassword"
    click_button "登録する"

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_content("新規登録が完了しました")
  end

  it "メールアドレス未入力では登録できない" do
    visit new_user_registration_path

    fill_in "user[name]", with: "失敗テスト"
    fill_in "user[email]", with: ""
    fill_in "user[password]", with: "password"
    fill_in "user[password_confirmation]", with: "password"
    click_button "登録する"

    expect(page).to have_content("メールアドレスを入力してください")
  end

  it "既存メールアドレスでは登録できない" do
    visit new_user_registration_path

    fill_in "user[name]", with: "重複ユーザー"
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    fill_in "user[password_confirmation]", with: "password"
    click_button "登録する"

    expect(page).to have_content("メールアドレスはすでに存在します")
  end

  describe "パスワードリセット" do
    it "登録済みメールアドレスでリセットリンクを送信できる" do
      visit new_user_password_path

      fill_in "user[email]", with: user.email
      click_button "リセットリンクを送信"

      expect(page).to have_content("パスワード再設定のためのメールを送信しました。")
      expect(ActionMailer::Base.deliveries.count).to eq(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include("パスワードの再設定")

      # メール文言チェック（name + 文中の文言 + リンクテキスト）
      expect(mail.body.encoded).to include("#{user.name}様")
      expect(mail.body.encoded).to include("以下のリンクをクリックすることで、パスワードの変更が可能です")
      expect(mail.body.encoded).to include("パスワードを変更する") # リンクテキスト
    end

    it "未登録メールアドレスではエラーになる" do
      visit new_user_password_path

      fill_in "user[email]", with: "notfound@example.com"
      click_button "リセットリンクを送信"

      expect(page).to have_content("メールアドレスが見つかりません")
    end

    it "リセットリンクからパスワードを再設定できる" do
      token = user.send_reset_password_instructions
      visit edit_user_password_path(reset_password_token: token)

      fill_in "user[password]", with: "newsecurepass"
      fill_in "user[password_confirmation]", with: "newsecurepass"
      click_button "パスワードを変更"

      expect(page).to have_content("パスワードを変更しました。")
      expect(page).to have_current_path("/")

      # 念のため再ログイン確認
      click_link "ログアウト", match: :first
      visit new_user_session_path
      fill_in "user[email]", with: user.email
      fill_in "user[password]", with: "newsecurepass"
      click_button "ログイン"

      expect(page).to have_current_path(home_index_path)
    end
  end
end
