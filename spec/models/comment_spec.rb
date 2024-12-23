require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:user) { User.create(email: 'test@example.com', password: 'password', name: 'テストユーザー') }
  let(:review) { Review.create(title: 'テストレビュー', content: 'テスト内容', user: user) }

  describe 'コメントのバリデーション' do
    context '有効な場合' do
      it 'content, user, reviewが揃っていれば有効' do
        comment = Comment.new(content: 'テストコメント', user: user, review: review)
        expect(comment).to be_valid
      end

      it 'contentが最大文字数以内（300文字）であれば有効' do
        comment = Comment.new(content: 'a' * 300, user: user, review: review)
        expect(comment).to be_valid
      end
    end

    context '無効な場合' do
      it 'contentが空の場合は無効' do
        comment = Comment.new(content: nil, user: user, review: review)
        expect(comment).not_to be_valid
        expect(comment.errors[:content]).to include('コメントを入力してください')
      end

      it 'contentが300文字を超える場合は無効' do
        comment = Comment.new(content: 'a' * 301, user: user, review: review)
        expect(comment).not_to be_valid
        expect(comment.errors[:content]).to include('300文字以内で入力してください')
      end

      it 'userが関連付けられていない場合は無効' do
        comment = Comment.new(content: 'テストコメント', user: nil, review: review)
        expect(comment).not_to be_valid
      end

      it 'reviewが関連付けられていない場合は無効' do
        comment = Comment.new(content: 'テストコメント', user: user, review: nil)
        expect(comment).not_to be_valid
      end
    end
  end
end
