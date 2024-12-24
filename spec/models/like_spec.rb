require 'rails_helper'

RSpec.describe Like, type: :model do
  let!(:user) { create(:user) }
  let!(:review) { create(:review, user: user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'ユーザーとレビューがあれば有効であること' do
        like = build(:like, user: user, review: review)
        expect(like).to be_valid
      end
    end

    context '異常系' do
      it '同じユーザーとレビューの組み合わせが重複している場合は無効であること' do
        create(:like, user: user, review: review)
        duplicate_like = build(:like, user: user, review: review)
        expect(duplicate_like).not_to be_valid
        expect(duplicate_like.errors[:user_id]).to include('同じレビューに2回以上いいねできません')
      end

      it 'ユーザーが存在しない場合は無効であること' do
        like_without_user = build(:like, user: nil, review: review)
        expect(like_without_user).not_to be_valid
      end

      it 'レビューが存在しない場合は無効であること' do
        like_without_review = build(:like, user: user, review: nil)
        expect(like_without_review).not_to be_valid
      end
    end
  end
end
