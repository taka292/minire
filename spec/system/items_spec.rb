require 'rails_helper'

RSpec.describe "商品詳細ページ", type: :system do
  let!(:user) { create(:user) }

  context "商品情報の表示" do
    context "画像がある場合" do
      let!(:item) do
        create(:item, name: "ミニマル収納ボックス", price: "3500", manufacturer: "ミニマル社", amazon_url: "https://www.amazon.co.jp/dp/B012345678", description: "シンプルな収納ボックスです。")
      end

      before do
        item.images.attach(
          io: File.open(Rails.root.join("spec/fixtures/test_item.jpg")),
          filename: "test_item.jpg",
          content_type: "image/jpeg"
        )
      end

      it "商品情報と画像が表示される" do
        visit item_path(item)

        expect(page).to have_content("ミニマル収納ボックス")
        expect(page).to have_content("ミニマル社")
        expect(page).to have_content("¥3,500")
        expect(page).to have_content("シンプルな収納ボックスです。")
        expect(page).to have_link("Amazon", href: "https://www.amazon.co.jp/dp/B012345678")
        expect(page).to have_css("img[src*='test_item.jpg']")
      end
    end

    context "画像がない場合" do
      let!(:item) do
        create(:item, name: "画像なし商品", manufacturer: nil, price: nil, description: nil, amazon_url: nil)
      end

      it "画像未登録と情報なしが表示される" do
        visit item_path(item)

        expect(page).to have_content("画像未登録")
        expect(page).to have_content("画像なし商品")
        expect(page).to have_content("情報がありません").at_least(1).times
        expect(page).to have_content("Amazonのリンク情報は未登録です")
      end
    end
  end

  context "レビューの表示" do
    let!(:item) { create(:item, name: "レビュー付き商品") }
    let!(:review1) { create(:review, title: "最高のアイテム", content: "これは素晴らしいです", item:, user:) }
    let!(:review2) { create(:review, title: "まあまあ", content: "悪くないけどもう少し", item:, user:) }

    it "レビュー一覧が表示される" do
      visit item_path(item)

      expect(page).to have_content("レビュー一覧")
      expect(page).to have_content("最高のアイテム")
      expect(page).to have_content("まあまあ")
      expect(page).to have_content("これは素晴らしいです").or have_content("悪くないけどもう少し")
    end
  end

  context "レビューがない場合" do
    let!(:item) { create(:item, name: "レビューなし商品") }

    it "レビューがない旨が表示される" do
      visit item_path(item)

      expect(page).to have_content("この商品にはまだレビューがありません。")
    end
  end
end
