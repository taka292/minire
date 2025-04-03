require 'rails_helper'

RSpec.describe "いいね機能", type: :system do
  let!(:review) { create(:review) }
  let!(:user) { review.user }

  before do
    login(user)
    visit review_path(review)
  end

  describe "非同期のいいねのテスト", js: true do
    it "レビューにいいねできる" do
      within("#like_button_#{review.id}") do
        click_button
      end

      expect(page).to have_selector("span", text: "favorite")
      within("#likes_count_#{review.id}") do
        expect(page).to have_content("1")
      end
    end

    it "レビューのいいねを取り消せる" do
      review.likes.create!(user: user)
      visit current_path

      within("#like_button_#{review.id}") do
        click_button
      end

      expect(page).to have_selector("span", text: "favorite_border")
      within("#likes_count_#{review.id}") do
        expect(page).to have_content("0")
      end
    end

    it "ログアウト状態ではいいねできない" do
      logout
      visit review_path(review)

      within("#like_button_#{review.id}") do
        expect(page).to have_selector("span.material-icons", text: "favorite_border")
        expect(page).to have_css(".cursor-not-allowed")
      end
    end

    it "他のユーザーがいいねした場合にも数が正しく反映される" do
      create(:like, user: create(:user), review: review)
      visit current_path

      within("#likes_count_#{review.id}") do
        expect(page).to have_content("1")
      end

      within("#like_button_#{review.id}") do
        click_button
      end

      within("#likes_count_#{review.id}") do
        expect(page).to have_content("2")
      end
    end
  end
end
