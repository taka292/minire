require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:item) { build(:item) }

  describe "バリデーション" do
    context "正常系" do
      it "すべての値が正しい場合、有効である" do
        expect(item).to be_valid
      end

      it "Amazon URLが正しい形式であれば有効である" do
        item.amazon_url = "https://www.amazon.co.jp/dp/example"
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
        expect(item.errors[:name]).to include("商品名はすでに存在します")
      end

      it "Amazon URLが無効な形式の場合、無効である" do
        item.amazon_url = "invalid-url"
        expect(item).not_to be_valid
        expect(item.errors[:amazon_url]).to include("正しいURL形式を入力してください。")
      end
    end
  end
  describe '画像のアップロード' do
    context '正常系' do
      it '画像を複数枚アップロードできる' do
        item.images.attach(
          io: StringIO.new("dummy data 1"), filename: 'image1.png', content_type: 'image/png'
        )
        item.images.attach(
          io: StringIO.new("dummy data 2"), filename: 'image2.png', content_type: 'image/png'
        )

        expect(item.images.count).to eq(2) # アップロードされた画像が2枚であることを確認
        expect(item).to be_valid
      end
    end

    context '異常系' do
      it '無効な形式の画像をアップロードした場合は無効である' do
        item.images.attach(
          io: StringIO.new("invalid data"), filename: 'invalid.txt', content_type: 'text/plain'
        )

        expect(item).not_to be_valid
        expect(item.errors[:images]).to include('JPEG, PNGのみアップロードできます')
      end
    end
  end
end
