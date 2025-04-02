require 'rails_helper'

RSpec.describe "プロフィール機能", type: :system do
  let!(:user) { create(:user, name: "テストユーザー", password: "password") }

  before do
    ActionMailer::Base.deliveries.clear
    login(user)
  end

  describe "プロフィール表示画面" do
    it "ユーザー名と自己紹介が表示される" do
      user.update(introduction: "こんにちは、ミニマリストです！")
      visit profile_path(user)

      expect(page).to have_content(user.name)
      expect(page).to have_content("こんにちは、ミニマリストです！")
    end

    it "アバター未設定時はデフォルトアイコンが表示される" do
      visit profile_path(user)
      expect(page).to have_selector("span.material-symbols-outlined", text: "account_circle")
    end

    it "アバター設定時はアップロードした画像が表示される" do
      visit edit_profile_path(user)

      attach_file "user[avatar]", Rails.root.join("spec/fixtures/test_avatar.jpg")
      click_button "更新する"

      # 遷移エラーを防ぐために、wait: 5を指定
      expect(page).to have_current_path(profile_path(user), wait: 5)
      expect(page).to have_selector("img[src*='test_avatar.jpg']")
    end

    it "自分の投稿一覧が表示される" do
      review1 = create(:review, user:, title: "自分の投稿1")
      review2 = create(:review, user:, title: "自分の投稿2")

      visit profile_path(user)

      expect(page).to have_content("自分の投稿1")
      expect(page).to have_content("自分の投稿2")
    end

    it "いいねした投稿一覧が表示される" do
      other_user = create(:user)
      liked_review1 = create(:review, user: other_user, title: "いいねした投稿1")
      liked_review2 = create(:review, user: other_user, title: "いいねした投稿2")
      create(:like, user:, review: liked_review1)
      create(:like, user:, review: liked_review2)

      visit profile_path(user)
      click_link "いいねしたレビュー", match: :first
      expect(page).to have_current_path(likes_profile_path(user))

      expect(page).to have_content("いいねした投稿1")
      expect(page).to have_content("いいねした投稿2")
    end
  end

  describe "プロフィール編集" do
    it "ユーザー名と自己紹介を変更できる" do
      visit edit_profile_path(user)

      fill_in "user[name]", with: "更新後ユーザー名"
      fill_in "user[introduction]", with: "自己紹介文を更新しました"
      click_button "更新する"

      expect(page).to have_current_path(profile_path(user))
      expect(page).to have_content("更新後ユーザー名")
      expect(page).to have_content("自己紹介文を更新しました")
    end

    it "アバター画像をアップロードできる" do
      visit edit_profile_path(user)

      attach_file "user[avatar]", Rails.root.join("spec/fixtures/test_avatar.jpg")
      click_button "更新する"

      expect(page).to have_current_path(profile_path(user))
      expect(page).to have_selector("img")
    end

    it "ユーザー名が空だと更新できない" do
      visit edit_profile_path(user)

      fill_in "user[name]", with: ""
      click_button "更新する"

      expect(page).to have_content("ユーザー名を入力してください")
    end
  end

  describe "パスワード変更" do
    it "正しい現在のパスワードで更新できる" do
      visit edit_password_profile_path(user)

      fill_in "user[current_password]", with: "password"
      fill_in "user[password]", with: "newpassword"
      fill_in "user[password_confirmation]", with: "newpassword"
      click_button "パスワードを更新"

      expect(page).to have_content("パスワードを変更しました").or have_content("プロフィール")

      click_link "ログアウト", match: :first
      expect(page).to have_content("ログアウトしました")

      visit new_user_session_path
      fill_in "user[email]", with: user.email
      fill_in "user[password]", with: "newpassword"
      click_button "ログイン"

      expect(page).to have_current_path(home_index_path)
      expect(page).to have_content("ログインに成功しました")
    end

    it "現在のパスワードが間違っていると更新できない" do
      visit edit_password_profile_path(user)

      fill_in "user[current_password]", with: "wrongpass"
      fill_in "user[password]", with: "newpassword"
      fill_in "user[password_confirmation]", with: "newpassword"
      click_button "パスワードを更新"

      expect(page).to have_content("現在のパスワードが正しくありません")
    end
  end

  describe "メールアドレス変更" do
    def expect_confirmation_email_sent_to(email)
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(email)
      expect(mail.subject).to include("メールアドレス確認")
      expect(mail.body.encoded).to include("確認")
    end

    it "確認メールを送信できる" do
      visit edit_email_profile_path(user)

      fill_in "user[email]", with: "newemail@example.com"
      click_button "確認メールを送信"

      expect(page).to have_content("確認メールを送信しました")
      expect_confirmation_email_sent_to("newemail@example.com")
    end

    it "空欄ではメールアドレスを更新できない" do
      visit edit_email_profile_path(user)

      fill_in "user[email]", with: ""
      click_button "確認メールを送信"

      expect(page).to have_content("メールアドレスを入力してください")
    end

    it "既に存在するメールアドレスでは更新できない" do
      create(:user, email: "existing@example.com")
      visit edit_email_profile_path(user)

      fill_in "user[email]", with: "existing@example.com"
      click_button "確認メールを送信"

      expect(page).to have_content("メールアドレスはすでに存在します")
    end
  end
end
