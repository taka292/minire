require 'rails_helper'

RSpec.describe "レビュー投稿機能", type: :system do
  let!(:review) { create(:review) }
  let(:user) { review.user }
  let!(:category) { create(:category, name: "生活用品") }

  before do
    login(user)
  end

  describe "新規レビュー投稿" do
    it "MiniRe検索で正常にレビューを投稿できる" do
      visit new_review_path

      # amazonAPI使用ができない状況のため、MiniRe検索は一旦コメントアウト
      # choose "MiniRe検索"
      fill_in "item_name", with: "テストアイテム"
      select "生活用品", from: "review[category_id]"
      fill_in "review[title]", with: "タイトルテスト"
      fill_in "review[content]", with: "内容テスト"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path)
      expect(page).to have_content("レビューを投稿しました！")
      expect(page).to have_content("タイトルテスト")
    end

    # Amazon APIが有効になったらこのテストを有効にする
    #     it "Amazon検索でレビューを投稿できる" do
    #       visit new_review_path
    #
    #       choose "Amazon検索"
    #       fill_in "amazon_item_name", with: "Amazonテスト商品"
    #
    #       find("input[name='asin']", visible: false).set("B000000000")
    #
    #       select "生活用品", from: "review[category_id]"
    #       fill_in "review[title]", with: "Amazonレビュー"
    #       fill_in "review[content]", with: "Amazon商品についてのレビュー"
    #       click_button "投稿する"
    #
    #       expect(page).to have_current_path(reviews_path)
    #       expect(page).to have_content("レビューを投稿しました！")
    #     end


    it "必須項目未入力でバリデーションエラーが表示される" do
      visit new_review_path
      click_button "投稿する"

      expect(page).to have_content("商品名を入力してください").or have_content("カテゴリを選択してください")
    end

    it "手放せるものが空でも投稿できる" do
      visit new_review_path

      # choose "MiniRe検索"
      fill_in "item_name", with: "手放せる空"
      select "生活用品", from: "review[category_id]"
      fill_in "review[title]", with: "タイトル"
      fill_in "review[content]", with: "内容"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path)
      expect(page).to have_content("レビューを投稿しました！")
    end

    it "手放せるものを複数入力して投稿できる" do
      visit new_review_path

      # choose "MiniRe検索"
      fill_in "item_name", with: "手放せる複数"
      select "生活用品", from: "review[category_id]"
      fill_in "review[title]", with: "複数テスト"
      fill_in "review[content]", with: "手放せるものを2つ追加"
      fill_in "review[releasable_items_attributes][0][name]", with: "手放せる1"
      fill_in "review[releasable_items_attributes][1][name]", with: "手放せる2"
      fill_in "review[releasable_items_attributes][2][name]", with: "手放せる3"

      click_button "投稿する"
      expect(page).to have_content("レビューを投稿しました！")

      click_link "複数テスト"
      expect(page).to have_content("複数テスト")
      expect(page).to have_content("手放せる1")
      expect(page).to have_content("手放せる2")
      expect(page).to have_content("手放せる3")
    end

    it "画像を複数アップロードしてレビュー投稿できる" do
      visit new_review_path

      # choose "MiniRe検索"
      fill_in "item_name", with: "画像付きアイテム"
      select "生活用品", from: "review[category_id]"
      fill_in "review[title]", with: "画像レビュー"
      fill_in "review[content]", with: "画像ありレビューです"

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg"),
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "投稿する"

      # 投稿されたことの確認
      expect(page).to have_content("レビューを投稿しました！", wait: 5)
      expect(page).to have_css("img[src*='sample1.jpg']")
      expect(page).to have_css("img[src*='sample2.jpg']")
    end

    it "レビュー画像の1枚目が商品画像として登録される" do
      visit new_review_path

      # choose "MiniRe検索"
      fill_in "item_name", with: "画像コピーアイテム"
      select "生活用品", from: "review[category_id]"
      fill_in "review[title]", with: "商品画像自動登録"
      fill_in "review[content]", with: "画像1枚目がitemに登録されるテスト"

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg"),
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "投稿する"

      # 投稿されたことを確認
      expect(page).to have_content("レビューを投稿しました！", wait: 5)

      item = Item.find_by(name: "画像コピーアイテム")
      expect(item).to be_present
      expect(item.images.attached?).to be true
      expect(item.images.first.filename.to_s).to eq("sample1.jpg")
    end
  end

  describe "レビューの編集と削除" do
    it "レビュー詳細が表示される" do
      visit review_path(review)
      expect(page).to have_content(review.title)
      expect(page).to have_content(review.content)
    end

    it "レビューを編集して内容が更新される" do
      review.releasable_items.create!(name: "古い手放せるもの")

      visit edit_review_path(review)

      fill_in "review[title]", with: "編集タイトル"
      fill_in "review[content]", with: "編集内容"

      fill_in "review[releasable_items_attributes][0][name]", with: "新しい手放せるもの"

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")
      expect(page).to have_content("編集タイトル")
      expect(page).to have_content("編集内容")
      expect(page).to have_content("新しい手放せるもの")
    end


    it "レビューを削除できる" do
      visit review_path(review)
      accept_confirm { find("a[title='レビュー削除']").click }

      expect(page).to have_content("レビューを削除しました。")
      expect(current_path).to eq(reviews_path)
      expect(page).not_to have_content(review.title)
    end

    it "レビュー編集画面で手放せるものを削除できる" do
      review.releasable_items.create!(name: "削除予定のアイテム")

      visit edit_review_path(review)

      expect(page).to have_field("review[releasable_items_attributes][0][name]", with: "削除予定のアイテム")

      # 手放せるものを空にする
      fill_in "review[releasable_items_attributes][0][name]", with: ""
      click_button "更新する"
      expect(page).to have_content("レビューを更新しました！")
      expect(page).not_to have_content("削除予定のアイテム")
    end

    it "編集画面で画像を削除できる" do
      visit edit_review_path(review)

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg"),
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "更新する"

      # 投稿されたことを確認
      expect(page).to have_current_path(edit_review_path(review), wait: 5)
      expect(page).to have_content("レビューを更新しました！")
      visit edit_review_path(review)

      # 画像が2つ表示されていることを確認
      expect(page).to have_css("img[src*='sample1.jpg']")
      expect(page).to have_css("img[src*='sample2.jpg']")

      # 「×」ボタンを押して画像を削除する（最初の画像）
      all("button", text: "×").first.click

      click_button "更新する"

      # 画像が削除されたことを確認
      expect(page).to have_current_path(review_path(review), wait: 5)
      expect(page).to have_content("レビューを更新しました！")

      # どちらか一方の画像が残っている（両方削除するなら2つともnot_to）
      expect(page).not_to have_css("img[src*='sample1.jpg']")
    end

    it "編集画面で画像を追加アップロードできる" do
      visit edit_review_path(review)

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg")
      ], make_visible: true

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")

      visit edit_review_path(review)

      # すでに1つ表示されていることを確認
      expect(page).to have_css("img[src*='sample1.jpg']")

      # 新しい画像を追加アップロード
      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "更新する"

      # 投稿されたことの確認
      expect(page).to have_content("レビューを更新しました！", wait: 5)
      expect(page).to have_css("img[src*='sample1.jpg']")
      expect(page).to have_css("img[src*='sample2.jpg']")
    end
  end

  describe "レビュー一覧・並び替え・絞り込み" do
    let!(:review_with_releasable) do
      create(:review, title: "手放せるテスト", content: "手放せるレビューです").tap do |review|
        review.releasable_items.create!(name: "手放すもの1")
      end
    end

    it "レビュー一覧に表示される" do
      visit reviews_path
      expect(page).to have_content(review.title)
    end

    it "並び替えが正しく動作する" do
      visit reviews_path(sort: "oldest")
      expect(page.text.index("テストタイトル")).to be < page.text.index("手放せるテスト")
    end

    it "カテゴリで絞り込める" do
      visit reviews_path(filter_type: "category_#{category.id}")
      expect(page).to have_content(category.name)
    end

    it "手放せるもので絞り込める" do
      visit reviews_path(filter_type: "releasable")
      expect(page).to have_content("手放せるテスト")
      expect(page).to have_content("手放せるレビューです")
    end

    it "検索キーワードで絞り込める" do
      visit reviews_path(query: review.title)
      expect(page).to have_content(review.title)
    end

    it "カテゴリ絞り込み + 検索が正しく動作する" do
      # 絞り込みと検索対象になるレビューを作成
      create(:review, title: "掃除機レビュー", content: "これは生活用品", category:, item: create(:item, name: "スティック掃除機"))

      visit reviews_path(filter_type: "category_#{category.id}", query: "掃除機")

      expect(page).to have_content("掃除機レビュー")
      expect(page).to have_content("これは生活用品")
    end
  end

  describe "レビュー一覧・詳細での商品情報表示" do
    let!(:item) do
      item = create(:item)
      item.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/test_item.jpg")),
        filename: "test_item.jpg",
        content_type: "image/jpeg"
      )
      item
    end

    let!(:review_with_item) { create(:review, title: "テーブルレビュー", content: "とても気に入ってます", item:) }

    it "レビュー一覧に商品情報が表示される" do
      visit reviews_path

      expect(page).to have_content("ミニマリスト用テーブル")
      expect(page).to have_content("abc株式会社")
      expect(page).to have_css("img[src*='test_item.jpg']")
    end

    it "レビュー詳細に商品情報が表示される" do
      visit review_path(review_with_item)

      expect(page).to have_content("ミニマリスト用テーブル")
      expect(page).to have_content("abc株式会社")
      expect(page).to have_css("img[src*='test_item.jpg']")
    end
  end
end
