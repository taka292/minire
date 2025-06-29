require 'rails_helper'

RSpec.describe "コメント機能", type: :system do
  let!(:review) { create(:review) }
  let!(:user) { review.user }

  before do
    login(user)
    visit review_path(review)
  end

  describe "非同期のコメント機能のテスト", js: true do
    # Turbo Frameの描画が不安定なため、CI環境ではスキップ
    it "コメントが正常に投稿でき、新規順で表示される" do
      skip "CI環境ではTurbo描画の不安定性によりスキップ" if ENV["CI"]

      fill_in "comment_content", with: "1回目のコメント"
      click_button "コメント"
      expect(page).to have_selector("turbo-frame[id^='comment_']", wait: 10)
      expect(page).to have_content("1回目のコメント", wait: 5)

      fill_in "comment_content", with: "2回目のコメント"
      click_button "コメント"
      expect(page).to have_selector("turbo-frame[id^='comment_']", wait: 10)
      expect(page).to have_content("2回目のコメント", wait: 5)

      # コメントが最新のが上に表示されることを確認
      expect(page.text.index("2回目のコメント")).to be < page.text.index("1回目のコメント")
    end

    it "自分のコメントを非同期で削除できる" do
      review.comments.create!(content: "削除対象コメント", user: user)
      visit current_path

      expect(page).to have_content("削除対象コメント")

      accept_confirm do
        find("a#button-delete-#{Comment.last.id}").click
      end

      expect(page).not_to have_content("削除対象コメント")
    end

    it "自分のコメントを非同期で編集できる" do
      comment = review.comments.create!(content: "編集前のコメント", user: user)
      visit current_path

      # 編集リンクをクリック
      find("a[href='#{edit_review_comment_path(review, comment)}']").click

      # 編集フォームのTurbo Frame内で内容を書き換えて投稿
      within("#comment_#{comment.id}_form") do
        fill_in "comment_content", with: "編集後のコメント"
        click_button "更新する"
      end

      # 編集後の内容が表示され、古い内容は消えていることを確認
      expect(page).to have_content("編集後のコメント")
      expect(page).not_to have_content("編集前のコメント")
    end


    it "空のコメントを投稿するとバリデーションエラーが表示される" do
      fill_in "comment_content", with: ""
      click_button "コメント"

      expect(page).to have_content("コメントの投稿に失敗しました。")
    end

    it "他人のコメントには削除ボタンが表示されない" do
      other_user = create(:user)
      review.comments.create!(content: "他人のコメント", user: other_user)

      visit current_path

      expect(page).to have_content("他人のコメント")
      expect(page).not_to have_selector("a", id: "button-delete-#{Comment.last.id}")
    end

    #     今後「未ログインでもコメント閲覧OK」にする可能性があるため、一旦コメントアウト。
    #     投稿はログイン必須のままの場合は、このテストは必要。
    #     it "ログアウト状態ではコメントフォームが表示されない" do
    #       logout
    #       visit review_path(review)
    #
    #       expect(page).not_to have_selector("form#new_comment")
    #       expect(page).to have_content("ログインしてコメントする")
    #     end

    it "ログアウト状態ではコメント一覧が表示されない" do
      review.comments.create!(content: "表示されないはずのコメント", user: user)
      logout
      # テストだとcookieが残ってしまうので、意図的に削除
      page.driver.browser.manage.delete_all_cookies
      visit review_path(review)

      expect(page).not_to have_content("表示されないはずのコメント")
      expect(page).not_to have_selector("#comments")
      expect(page).to have_content("コメントを見るには")
    end
  end
end
