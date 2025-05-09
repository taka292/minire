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
        it "複数のアイテムと関連付けできる" do
          create(:item, category: category)
          create(:item, category: category)

          expect(category.items.count).to eq(2)
        end
    end
  end

  describe "acts_as_list（並び順）" do
    let!(:cat1) { create(:category, name: "A", position: 1) }
    let!(:cat2) { create(:category, name: "B", position: 2) }

    it "カテゴリの順序を上に移動できる" do
      cat2.move_higher
      expect(Category.order(position: :asc).map(&:name)).to eq([ "B", "A" ])
    end

    it "カテゴリの順序を下に移動できる" do
      cat1.move_lower
      expect(Category.order(position: :asc).map(&:name)).to eq([ "B", "A" ])
    end
  end
end
