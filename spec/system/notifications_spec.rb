require 'rails_helper'

RSpec.describe "通知機能", type: :system do
  let!(:sender)   { create(:user, name: "通知送信者") }
  let!(:receiver) { create(:user, name: "通知受信者") }
  let!(:review)   { create(:review, user: receiver, title: "通知対象のレビュー") }

  before do
    login(receiver)
  end

  describe "通知一覧画面" do
    context "いいね通知" do
      before do
        create(:like, user: sender, review: review)
        review.create_notification_favorite_review!(sender)
      end

      it "未読セクションにいいね通知が表示される" do
        visit notifications_path

        expect(page).to have_selector("h3", text: "未読の通知")
        expect(page).to have_content("通知送信者 さんがあなたの投稿に いいねしました")
      end

      it "通知をすべて既読にすると未読の通知が消える" do
        visit notifications_path

        # ボタンを押す前に「未読の通知」があることを確認
        expect(page).to have_content("未読の通知", wait: 3)

        # 既読にするボタンを押下
        click_button "通知をすべて既読にする"

        # 「未読の通知」が消える（または消えた旨の文言に変わる）ことだけ確認
        expect(page).to have_content("未読の通知はありません", wait: 5)
      end

      it "通知内のユーザー名リンクからプロフィールへ遷移できる" do
        visit notifications_path

        click_link "通知送信者", match: :first
        expect(page).to have_current_path(profile_path(sender))
        expect(page).to have_content("通知送信者さんのプロフィール")
      end

      it "通知内のレビューリンクからレビュー詳細へ遷移できる" do
        visit notifications_path

        click_link "いいねしました", match: :first
        expect(page).to have_current_path(review_path(review))
        expect(page).to have_content("通知対象のレビュー")
      end
    end

    context "コメント通知" do
      before do
        comment = create(:comment, review:, user: sender, content: "通知テストコメント")
        review.create_notification_comment!(sender, comment.id)
      end

      it "未読セクションにコメント通知が表示される" do
        visit notifications_path

        expect(page).to have_selector("h3", text: "未読の通知")
        expect(page).to have_content("通知送信者 さんがあなたの投稿に コメントしました")
      end

      it "通知をすべて既読にすると未読の通知が消える" do
        visit notifications_path

        # ボタンを押す前に「未読の通知」があることを確認
        expect(page).to have_content("未読の通知", wait: 3)

        # 既読にするボタンを押下
        click_button "通知をすべて既読にする"

        # 「未読の通知」が消える（または消えた旨の文言に変わる）ことだけ確認
        expect(page).to have_content("未読の通知はありません", wait: 5)
      end

      it "通知内のユーザー名リンクからプロフィールへ遷移できる" do
        visit notifications_path

        click_link "通知送信者", match: :first
        expect(page).to have_current_path(profile_path(sender))
        expect(page).to have_content("通知送信者さんのプロフィール")
      end

      it "通知内のレビューリンクからレビュー詳細へ遷移できる" do
        visit notifications_path

        click_link "コメントしました", match: :first
        expect(page).to have_current_path(review_path(review))
        expect(page).to have_content("通知対象のレビュー")
      end
    end
  end
end
