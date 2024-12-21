require 'rails_helper'

RSpec.describe ReleasableItem, type: :model do
  let(:user) { User.create!(
      email: 'test@example.com',
      password: 'password',
      password_confirmation: 'password',
      name: 'テストユーザー') }
  let(:review) { Review.create!(title: 'テストレビュー', content: 'テストコンテンツ', user: user) }

  describe 'バリデーション' do
    it 'nameとreviewがあれば有効である' do
      item = ReleasableItem.new(name: '手放せるアイテム', review: review)
      expect(item).to be_valid
    end

    # 動的なフォームにした後に下記テスト実施
    # it 'nameが空だと無効である' do
    #   item = ReleasableItem.new(name: nil, review: review)
    #   expect(item).not_to be_valid
    #   expect(item.errors[:name]).to include('を入力してください')
    # end

    it 'reviewが関連付けられていないと無効である' do
      item = ReleasableItem.new(name: '手放せるアイテム', review: nil)
      expect(item).not_to be_valid
      expect(item.errors[:review]).to include('を入力してください')
    end
  end
end
