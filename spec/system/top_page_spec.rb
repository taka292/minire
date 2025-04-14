require 'rails_helper'

RSpec.describe 'トップページのCTA表示', type: :system do
  let!(:user) { create(:user) }

  context '未ログイン時' do
    it 'レビューを見るボタン・新規登録ボタンが表示されている' do
      visit root_path
      expect(page).to have_link('レビューを見る', href: reviews_path)
      expect(page).to have_link('新規登録', href: new_user_registration_path)
    end
  end

  context 'ログイン時' do
    it 'レビューを見るボタン・レビュー投稿ボタンが表示されている' do
      sign_in user
      visit root_path
      expect(page).to have_link('レビューを見る', href: reviews_path)
      expect(page).to have_link('レビュー投稿', href: new_review_path)
      expect(page).not_to have_link('新規登録')
    end
  end
end
