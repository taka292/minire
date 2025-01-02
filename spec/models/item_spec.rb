require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:item) { build(:item) }

  describe "バリデーション" do
    context "正常系" do
      it "すべての値が正しい場合、有効である" do
        expect(item).to be_valid
      end
    end

    context "異常系" do
      it "名前が空の場合、無効である" do
        item.name = nil
        expect(item).not_to be_valid
        expect(item.errors[:name]).to include("商品名を入力してください")
      end

      it "名前が50文字を超える場合、無効である" do
        item.name = "あ" * 51
        expect(item).not_to be_valid
        expect(item.errors[:name]).to include("50文字以内で入力してください")
      end

      it "名前がすでに存在する場合（大文字小文字を区別しない）、無効である" do
        create(:item, name: "ミニマリスト用テーブル")
        item.name = "ミニマリスト用テーブル" # 同じ名前
        expect(item).not_to be_valid
        expect(item.errors[:name]).to include("はすでに存在します")
      end
    end
  end
end
