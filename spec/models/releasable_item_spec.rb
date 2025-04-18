require 'rails_helper'

RSpec.describe ReleasableItem, type: :model do
  let(:review) { create(:review) }

  describe 'バリデーション' do
    it 'nameとreviewがあれば有効である' do
      item = build(:releasable_item, review: review, name: '手放せるアイテム')
      expect(item).to be_valid
    end

    # 長さチェック
    it 'nameが50文字以内であれば有効である' do
      item = build(:releasable_item, review: review, name: 'a' * 50)
      expect(item).to be_valid
    end

    it 'nameが51文字以上であれば無効である' do
      item = build(:releasable_item, review: review, name: 'a' * 51)
      expect(item).not_to be_valid
      expect(item.errors[:name]).to include('50文字以内で入力してください')
    end

    # 動的なフォームにした後に下記テスト実施
    # it 'nameが空だと無効である' do
    #   item = build(:releasable_item, review: review, name: nil)
    #   expect(item).not_to be_valid
    #   expect(item.errors[:name]).to include('を入力してください')
    # end

    it 'reviewが関連付けられていないと無効である' do
      item = build(:releasable_item, review: nil)
      expect(item).not_to be_valid
      expect(item.errors[:review]).to include('を入力してください')
    end
  end
end
