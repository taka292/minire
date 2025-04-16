require 'rails_helper'

RSpec.describe "ユーザー認証", type: :system do
  let!(:user) { create(:user, email: "test@example.com", password: "password") }

  def log_in(email:, password:)
    visit new_user_session_path
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    click_button "ログイン"
  end

  it "正しい情報でログインできる(レビュー投稿無し)" do
    log_in(email: user.email, password: user.password)

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_content("ログインしました！さっそくレビューを投稿してみませんか？")
  end

  it "正しい情報でログインできる(レビュー投稿あり)" do
    log_in(email: user.email, password: user.password)
    create(:review, user: user)

    expect(page).to have_current_path(home_index_path)
    expect(page).to have_content("ログインしました！")
  end

  it "間違ったパスワードではログインに失敗する" do
    log_in(email: user.email, password: "wrongpassword")

    expect(page).to have_content("メールアドレスまたはパスワードが正しくありません。")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "未ログイン状態で保護ページにアクセスするとログイン画面にリダイレクトされる" do
    visit profile_path(user.id)

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("ログイン")
  end

  it "ログイン後にマイページにアクセスできる" do
    log_in(email: user.email, password: user.password)

    visit profile_path(user.id, wait: 5)
    expect(page).to have_current_path(profile_path(user.id), wait: 5)
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
    expect(page).to have_content("登録ありがとうございます！さっそくレビューを投稿してみませんか？")
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
      visit profile_path(user)
      expect(page).to have_content("テストユーザー")
      click_link "ログアウト"
      visit new_user_session_path
      expect(page).to have_current_path(new_user_session_path, wait: 5)
      fill_in "user[email]", with: user.email
      fill_in "user[password]", with: "newsecurepass"
      click_button "ログイン"

      expect(page).to have_current_path(home_index_path)
    end
  end

  describe "SNS認証（Google）" do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: SecureRandom.uuid,
        info: {
          email: "snsuser@example.com",
          name: "SNSユーザー"
        }
      )
    end

    after do
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    it "ログイン画面からGoogleログインに成功し、ユーザーが作成・ログインされる" do
      visit new_user_session_path

      find("form[action='#{user_google_oauth2_omniauth_authorize_path}']").click_button

      expect(page).to have_current_path("/")
      expect(page).to have_content("Google認証成功しました！さっそくレビューを投稿してみませんか？")
    end

    it "新規登録画面からGoogle認証に成功し、ユーザーが作成・ログインされる" do
      visit new_user_registration_path

      find("form[action='#{user_google_oauth2_omniauth_authorize_path}']").click_button

      expect(page).to have_current_path("/")
      expect(page).to have_content("Google認証成功しました！さっそくレビューを投稿してみませんか？")
    end

    it "通常登録済みのメールアドレスではSNS登録できない" do
      # 先に通常登録
      create(:user, email: "duplicate@example.com", password: "password", name: "通常ユーザー")

      # SNSログイン設定
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: SecureRandom.uuid,
        info: {
          email: "duplicate@example.com",
          name: "SNSユーザー"
        }
      )

      visit new_user_session_path

      find("form[action='#{user_google_oauth2_omniauth_authorize_path}']").click_button

      # 登録できずログイン画面にリダイレクトされていることを確認
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content("このメールアドレスは別のログイン方法で既に登録されています。登録時の方法（通常登録またはSNS認証）でログインしてください。") # またはカスタムメッセージ
    end

    it "SNS認証で既存のメールアドレスを使用した場合はログインできず、案内される" do
      # 通常登録済みユーザー
      create(:user, email: "duplicate@example.com")

      # SNSログイン用のモック（同じメール）
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "some-uid",
        info: {
          email: "duplicate@example.com",
          name: "ダブリユーザー"
        }
      )

      visit new_user_session_path
      find("form[action='#{user_google_oauth2_omniauth_authorize_path}']").click_button

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content("このメールアドレスは別のログイン方法で既に登録されています。登録時の方法（通常登録またはSNS認証）でログインしてください。")
    end
  end
end
