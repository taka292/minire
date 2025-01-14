require 'rails_helper'

RSpec.describe Category, type: :model do
  let(:category) { create(:category) }
  let(:user) { create(:user) }
  let(:item) { create(:item) }

  describe "バリデーション" do
    context "正常系" do
      it "すべての値が正しい場合、有効である" do
        expect(category).to be_valid
      end

      it "一意のカテゴリ名が有効である" do
        category.name = "ファッション"
        expect(category).to be_valid
      end
    end

    context "異常系" do
      it "名前が空の場合、無効である" do
        category.name = nil
        expect(category).not_to be_valid
        expect(category.errors[:name]).to include("カテゴリ名を入力してください")
      end

      it "名前がすでに存在する場合、無効である" do
        create(:category, name: "家電")
        category.name = "家電" # 同じ名前
        expect(category).not_to be_valid
        expect(category.errors[:name]).to include("カテゴリ名はすでに存在します")
      end
    end
  end

  describe "アソシエーション" do
    context "関連付け" do
      it "複数のレビューと関連付けできる" do
        create(:review, category: category, user: user, item: item)
        create(:review, category: category, user: user, item: item)

        expect(category.reviews.count).to eq(2)
      end
    end
  end
end
