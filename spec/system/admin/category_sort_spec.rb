require 'rails_helper'

RSpec.describe "カテゴリの並び替え機能", type: :system do
  let!(:admin_user) { create(:user, email: "admin@example.com", password: "password", admin: true) }
  let!(:cat1) { create(:category, name: "A", position: 1) }
  let!(:cat2) { create(:category, name: "B", position: 2) }
  let!(:item1) { create(:item, name: "Item A", category: cat1) }
  let!(:item2) { create(:item, name: "Item B", category: cat2) }

  before do
    visit new_user_session_path
    fill_in "user[email]", with: admin_user.email
    fill_in "user[password]", with: admin_user.password
    click_button "ログイン"
    expect(page).to have_content("ログインしました")

    visit admin_categories_path
  end

  def move_category_b_higher
    within(:xpath, "//tr[td[contains(text(), 'B')]]") do
      click_link "上へ"
    end
  end

  def category_names_from_admin_page
    visit admin_categories_path
    all("tbody tr td:first-child").map(&:text)
  end

  def category_names_from_filter_select
    visit reviews_path
    select_box = find("select[name='filter_type']")
    select_box.all("option").map(&:text)
  end

  it "カテゴリの並び替えが管理画面とレビュー一覧ページに反映される" do
    move_category_b_higher

    # 管理画面で順序を確認
    expect(category_names_from_admin_page).to eq([ "B", "A" ])

    # レビュー一覧ページのセレクトボックスで順序を確認
    options = category_names_from_filter_select
    index_b = options.index { |text| text.include?("カテゴリ: B") }
    index_a = options.index { |text| text.include?("カテゴリ: A") }

    expect(index_b).to be < index_a
  end
end
