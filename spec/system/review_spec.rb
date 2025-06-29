require 'rails_helper'

RSpec.describe "レビュー投稿機能", type: :system do
  let!(:review) { create(:review) }
  let(:user) { review.user }
  let!(:category) { create(:category, name: "その他") }

  before do
    login(user)

    category = create(:category, name: "ガジェット・家電")

    imported_item = Item.create!(
      asin: "B000000000",
      name: "Amazonテスト商品",
      last_updated_at: Time.current,
      category: category
    )

    allow(AmazonItemImporter).to receive(:new).and_return(
      double(import!: imported_item)
    )
  end

  describe "新規レビュー投稿" do
    it "サイト内検索（見つからない場合）で正常にレビューを投稿できる" do
      visit new_review_path

      click_button "見つからない場合" # ← サイト内フォーム表示
      fill_in "item_name", with: "テストアイテム"
      fill_in "review[title]", with: "タイトルテスト"
      fill_in "review[content]", with: "内容テスト"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path, wait: 5)
      expect(page).to have_content("レビューを投稿しました！")
      expect(page).to have_content("タイトルテスト")

      # 投稿されたレビューを取得してカテゴリ確認
      created_review = Review.find_by(title: "タイトルテスト")
      expect(created_review).to be_present
      expect(created_review.item.category.name).to eq("その他")
    end

    it "Amazon検索でレビューを投稿できる" do
      visit new_review_path

      # 非表示でもJSで埋める
      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazonテスト商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "Amazonレビュー"
      fill_in "review[content]", with: "Amazon商品についてのレビュー"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path)
      expect(page).to have_content("レビューを投稿しました！")
    end

    it "必須項目未入力でバリデーションエラーが表示される" do
      visit new_review_path
      click_button "投稿する"

      expect(page).to have_content("Amazonの商品名に誤りがあります")
    end

    it "手放せるものが空でも投稿できる" do
      visit new_review_path

      click_button "見つからない場合"
      fill_in "item_name", with: "手放せる空"
      fill_in "review[title]", with: "タイトル"
      fill_in "review[content]", with: "内容"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path)
      expect(page).to have_content("レビューを投稿しました！")
    end

    it "手放せるものを複数入力して投稿できる" do
      visit new_review_path

      click_button "見つからない場合"
      fill_in "item_name", with: "手放せる複数"
      fill_in "review[title]", with: "複数テスト"
      fill_in "review[content]", with: "手放せるものを2つ追加"

      # 手放せるものをJSで追加する必要がある場合、Stimulusで対応
      # ここではname入力を直接追加（fields_forで表示される前提）
      click_button "手放せるものを追加"
      fill_in "review[releasable_items_attributes][0][name]", with: "手放せる1"
      click_button "手放せるものを追加"
      fill_in "review[releasable_items_attributes][1][name]", with: "手放せる2"
      click_button "手放せるものを追加"
      fill_in "review[releasable_items_attributes][2][name]", with: "手放せる3"

      click_button "投稿する"
      expect(page).to have_content("レビューを投稿しました！")

      click_link "複数テスト"
      expect(page).to have_content("手放せる1")
      expect(page).to have_content("手放せる2")
      expect(page).to have_content("手放せる3")
    end

    it "画像を複数アップロードしてレビュー投稿できる" do
      visit new_review_path

      click_button "見つからない場合"
      fill_in "item_name", with: "画像付きアイテム"
      fill_in "review[title]", with: "画像レビュー"
      fill_in "review[content]", with: "画像ありレビューです"

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg"),
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "投稿する"

      expect(page).to have_content("レビューを投稿しました！", wait: 10)
      expect(page).to have_css("img[src*='sample1.jpg']")
      expect(page).to have_css("img[src*='sample2.jpg']")
    end

    it "レビュー画像の1枚目が商品画像として登録される" do
      visit new_review_path

      click_button "見つからない場合"
      fill_in "item_name", with: "画像コピーアイテム"
      fill_in "review[title]", with: "商品画像自動登録"
      fill_in "review[content]", with: "画像1枚目がitemに登録されるテスト"

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg"),
        Rails.root.join("spec/fixtures/sample2.jpg")
      ], make_visible: true

      click_button "投稿する"

      expect(page).to have_content("レビューを投稿しました！", wait: 10)

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
      other_category = Category.find_or_create_by!(name: "その他")
      item = create(:item, category: other_category)
      review = create(:review, user:, item:)

      review.releasable_items.create!(name: "古い手放せるもの")

      visit edit_review_path(review)

      fill_in "review[title]", with: "編集タイトル"
      fill_in "review[content]", with: "編集内容"

      click_button "手放せるものを追加"
      fill_in "review[releasable_items_attributes][0][name]", with: "新しい手放せるもの"

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")
      expect(page).to have_content("編集タイトル")
      expect(page).to have_content("編集内容")
      expect(page).to have_content("新しい手放せるもの")

      edited_review = Review.find_by(title: "編集タイトル")
      expect(edited_review).to be_present
      expect(edited_review.item.category.name).to eq("その他")
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
      expect(page).to have_current_path(edit_review_path(review), wait: 20)
      expect(page).to have_content("レビューを更新しました！", wait: 5)
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

    it "サイト内検索で新しい商品名を入力してレビューを編集できる" do
      item = create(:item, name: "旧商品")
      review = create(:review, user:, item:)

      visit edit_review_path(review)

      fill_in "item_name", with: "MiniRe編集商品" # 新しい商品名

      fill_in "review[title]", with: "MiniRe編集後のタイトル"
      fill_in "review[content]", with: "MiniRe編集後の内容"

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")
      expect(page).to have_content("MiniRe編集後のタイトル")
      expect(page).to have_content("MiniRe編集後の内容")

      updated_review = Review.find_by(title: "MiniRe編集後のタイトル")
      expect(updated_review).to be_present
      expect(updated_review.item.name).to eq("MiniRe編集商品")
      expect(updated_review.item.category.name).to eq("その他")
    end
  end

  describe "レビュー一覧・並び替え・絞り込み" do
    let!(:review_with_releasable) do
      create(:review, title: "手放せるテスト", content: "手放せるレビューです").tap do |review|
        review.releasable_items.create!(name: "手放すもの1")
      end
    end

    let!(:category) { create(:category, name: "家電") }
    let!(:other_category) { create(:category, name: "掃除機") }

    let!(:item1) { create(:item, name: "スティック掃除機", category:) }
    let!(:item2) { create(:item, name: "炊飯器", category:) }
    let!(:item3) { create(:item, name: "掃除機", category: other_category) }

    let!(:review1) { create(:review, title: "掃除機レビュー", content: "新しい掃除機です", item: item1) }
    let!(:review2) { create(:review, title: "旧掃除機レビュー", content: "これは古い掃除機です", item: item1) }
    let!(:review3) { create(:review, title: "炊飯器レビュー", content: "これは炊飯器です", item: item2) }
    let!(:review4) { create(:review, title: "掃除機レビュー2", content: "新しい掃除機2です", item: item3) }

    before do
      create_list(:like, 3, review: review1)
      create(:like, review: review2)
    end

    def select_filter(value)
      select value, from: "filter_type"
    end

    def select_sort(value)
      select value, from: "sort"
    end

    def search_reviews_with(keyword)
      visit reviews_path
      find("input[name='q[title_or_content_or_item_name_or_item_description_or_item_asin_or_item_manufacturer_or_releasable_items_name_cont]']", match: :first).set(keyword)
      find("input[type='submit'][value='検索']", match: :first).click
    end

    it "レビュー一覧に表示される" do
      visit reviews_path
      expect(page).to have_content(review_with_releasable.title)
    end

    it "並び替えが正しく動作する" do
      create(:review, title: "テストタイトル", created_at: 1.day.ago)

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
      search_reviews_with(review_with_releasable.title)
      expect(page).to have_content(review_with_releasable.title)
    end

    it "item.description で検索できる" do
      item = create(:item, description: "高性能スピーカー")
      create(:review, title: "descriptionでヒットするレビュー", item:)

      search_reviews_with("高性能スピーカー")
      expect(page).to have_content("descriptionでヒットするレビュー")
    end

    it "item.asin で検索できる" do
      item = create(:item, asin: "B000TESTASIN")
      create(:review, title: "ASINでヒットするレビュー", item:)

      search_reviews_with("B000TESTASIN")
      expect(page).to have_content("ASINでヒットするレビュー")
    end

    it "item.manufacturer で検索できる" do
      item = create(:item, manufacturer: "MinimalTech")
      create(:review, title: "メーカーでヒットするレビュー", item:)

      search_reviews_with("MinimalTech")
      expect(page).to have_content("メーカーでヒットするレビュー")
    end

    it "releasable_items.name で検索できる" do
      review = create(:review, title: "手放せる名前でヒットするレビュー")
      review.releasable_items.create!(name: "手放せるレザーケース")

      search_reviews_with("手放せるレザーケース")
      expect(page).to have_content("手放せる名前でヒットするレビュー")
    end

    it "検索後にカテゴリ絞り込みといいね順ソートができる" do
      search_reviews_with("掃除機")

      expect(page).to have_content("掃除機レビュー")
      expect(page).to have_content("旧掃除機レビュー")
      expect(page).to have_content("掃除機レビュー2")
      expect(page).not_to have_content("炊飯器レビュー")

      select_filter("カテゴリ: #{category.name}")
      expect(page).to have_content("掃除機レビュー")
      expect(page).to have_content("旧掃除機レビュー")
      expect(page).not_to have_content("掃除機レビュー2")

      select_sort("いいねが多い順")
      expect(page.text.index("掃除機レビュー")).to be < page.text.index("旧掃除機レビュー")
    end

    it "カテゴリ絞り込みといいね順ソート後に検索ができる" do
      visit reviews_path

      select_filter("カテゴリ: #{category.name}")
      expect(page).to have_content("掃除機レビュー")
      expect(page).to have_content("旧掃除機レビュー")
      expect(page).not_to have_content("掃除機レビュー2")

      select_sort("いいねが多い順")
      expect(page.text.index("掃除機レビュー")).to be < page.text.index("旧掃除機レビュー")

      search_reviews_with("掃除機")
      expect(page).to have_content("掃除機レビュー")
      expect(page).to have_content("旧掃除機レビュー")
      expect(page).not_to have_content("炊飯器レビュー")
      expect(page.text.index("掃除機レビュー")).to be < page.text.index("旧掃除機レビュー")
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

    it "レビュー詳細にXシェアボタンが表示され、内容が含まれている" do
      review_with_image = create(:review, :with_images, user:)
      visit review_path(review_with_image)

      # シェアボタンが表示されていることを確認
      expect(page).to have_selector("a", text: "シェア")

      # OGP画像のmetaタグが含まれているか確認（head内を見るための裏技）
      og_image_tag = page.find("meta[property='og:image']", visible: false)
      expect(og_image_tag[:content]).to have_content("sample1.jpg")

      # intentリンクが含まれているか
      link = find("a", text: "シェア")[:href]
      expect(link).to include("https://twitter.com/intent/tweet")
      expect(link).to include(CGI.escape(review_with_image.title))
      include_text = CGI.escape(ActionController::Base.helpers.truncate(review_with_image.content, length: 50))
      expect(link).to include(include_text)
      expect(link).to include("minire")
    end

    it "レビュー一覧にAmazonリンクが表示される" do
      visit reviews_path
      expect(page).to have_link(href: item.amazon_url)
    end

    it "レビュー詳細にAmazonリンクが表示される" do
      visit review_path(review)
      expect(page).to have_link(href: item.amazon_url)
    end
  end

  describe "Amazon検索を使ったレビュー投稿" do
    it "ASINと商品名が両方ないと投稿できない（バリデーション）" do
      visit new_review_path

      # 両方空
      click_button "投稿する"

      expect(page).to have_content("Amazonの商品を選択してください")
    end

    it "ASINだけ入力されていても商品名がないと投稿できない" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B00ONLYASIN'")
      # 商品名は入力しない
      click_button "投稿する"

      expect(page).to have_content("Amazonの商品を選択してください")
    end

    it "商品名だけ入力されていてもASINがないと投稿できない" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = '名前だけの商品'")
      # ASINは入力しない
      click_button "投稿する"

      expect(page).to have_content("Amazonの商品を選択してください")
    end

    it "ASINと商品名を正しく入力すればレビューを投稿できる" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazonテスト商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "Amazonレビュー"
      fill_in "review[content]", with: "Amazon商品についてのレビュー"
      click_button "投稿する"

      expect(page).to have_current_path(reviews_path)
      expect(page).to have_content("レビューを投稿しました！")
      expect(Item.find_by(asin: "B000000000")).to be_present
    end

    it "画像付きAmazonレビューでは、1枚目の画像がitemにコピーされる" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazonテスト商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "画像付きAmazonレビュー"
      fill_in "review[content]", with: "画像がitemにコピーされるかテスト"

      attach_file "review[images][]", [
        Rails.root.join("spec/fixtures/sample1.jpg")
      ], make_visible: true

      click_button "投稿する"

      expect(page).to have_content("レビューを投稿しました！", wait: 5)

      item = Item.find_by(asin: "B000000000")
      expect(item).to be_present
      expect(item.images.attached?).to be true
      expect(item.images.first.filename.to_s).to eq("sample1.jpg")
    end


    it "AmazonItemImporterから取得した商品にlast_updated_atがセットされる" do
      asin = "B000DUMMY01"

      # ダミーItem（importerの戻り値として使う）
      imported_item = Item.new(asin:, name: "ダミー商品", last_updated_at: Time.current)
      allow(imported_item).to receive(:save!).and_return(true)

      # importerをstubして戻り値を差し替え
      expect(AmazonItemImporter).to receive(:new).with(asin).and_return(
        instance_double(AmazonItemImporter, import!: imported_item)
      )

      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'ダミー商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = '#{asin}'")

      fill_in "review[title]", with: "ダミー確認テスト"
      fill_in "review[content]", with: "インポート処理が呼ばれたかを簡易確認"

      click_button "投稿する"

      expect(page).to have_content("レビューを投稿しました！")
    end

    it "Amazon API経由のレビュー投稿時にカテゴリが自動で設定される" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazonテスト商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "カテゴリ自動設定テスト"
      fill_in "review[content]", with: "Amazon経由でカテゴリが設定されるかの確認"

      click_button "投稿する"

      expect(page).to have_content("レビューを投稿しました！")

      review = Review.find_by(title: "カテゴリ自動設定テスト")
      expect(review.item.category.name).to eq("ガジェット・家電")
    end
  end

  describe "Amazon検索を使ったレビュー編集" do
    let!(:editable_review) { create(:review, user:) }

    it "ASINと商品名を正しく指定すればAmazon商品に変更できる" do
      visit edit_review_path(editable_review)

      click_button "Amazon内で探す"

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazonテスト商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "編集後のAmazonレビュー"
      fill_in "review[content]", with: "編集してAmazon商品に切り替え"

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")
      expect(Item.find_by(asin: "B000000000")).to be_present
    end

    it "ASINや商品名が未入力だと編集に失敗する" do
      visit edit_review_path(editable_review)

      click_button "Amazon内で探す"

      # 両方空で更新
      click_button "更新する"

      expect(page).to have_content("Amazonの商品を選択してください")
    end

    it "AmazonItemImporterから取得した商品にlast_updated_atがセットされる（編集時）" do
      visit edit_review_path(editable_review)
      click_button "Amazon内で探す"

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = '編集ダミー商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "編集インポート確認"
      fill_in "review[content]", with: "編集でインポートが呼ばれるか確認"

      click_button "更新する"

      expect(page).to have_content("レビューを更新しました！")
    end
  end

  describe "レビューの下書き保存" do
    it "サイト内検索でレビューを下書き保存できる" do
      visit new_review_path

      click_button "見つからない場合"
      fill_in "item_name", with: "下書き用アイテム"
      fill_in "review[title]", with: "下書きタイトル"
      fill_in "review[content]", with: "これは下書きのレビューです"

      click_button "下書き保存"

      review = Review.find_by(title: "下書きタイトル")
      expect(page).to have_current_path(edit_review_path(review), wait: 5)
      expect(page).to have_content("レビューを下書き保存しました！")

      expect(review.status).to eq("draft")
      expect(review.title).to eq("下書きタイトル")
    end

    it "Amazon検索でレビューを下書き保存できる" do
      visit new_review_path

      page.execute_script("document.querySelector(\"input[name='amazon_item_name']\").value = 'Amazon下書き商品'")
      page.execute_script("document.querySelector(\"input[name='asin']\").value = 'B000000000'")

      fill_in "review[title]", with: "Amazon下書きタイトル"
      fill_in "review[content]", with: "Amazon商品の下書き"

      click_button "下書き保存"
      review = Review.find_by(title: "Amazon下書きタイトル")
      expect(page).to have_current_path(edit_review_path(review), wait: 5)
      expect(page).to have_content("レビューを下書き保存しました！")

      expect(review.status).to eq("draft")
      expect(review.item.asin).to eq("B000000000")
    end

    it "プロフィールページから下書きモーダル経由で編集に遷移できる" do
      draft_review = create(:review, user:, status: :draft, title: "モーダル下書き", content: "モーダルから編集")

      visit new_review_path
      click_button "下書きから作成"

      within("#draftModal") do
        expect(page).to have_content("モーダル下書き")
        click_link "モーダル下書き"
      end

      expect(page).to have_current_path(edit_review_path(draft_review), wait: 5)
      expect(find_field("review[title]").value).to eq("モーダル下書き")
    end

    it "下書きレビューは本人以外には表示されない" do
      other_user = create(:user)
      draft_review = create(:review, user: other_user, status: :draft, title: "他人の下書き")

      visit review_path(draft_review)

      expect(current_path).to eq(reviews_path)
      expect(page).to have_content("このレビューにはアクセスできません。")
    end
  end
end
