require 'rails_helper'

RSpec.describe Notification, type: :model do
  let!(:visitor) { create(:user) }
  let!(:visited) { create(:user) }
  let!(:review) { create(:review, user: visited) }
  let!(:comment) { create(:comment, user: visitor, review: review) }

  describe 'バリデーション' do
    context '正常系' do
      it 'いいねの通知が有効であること' do
        notification = build(:notification, :for_like, visitor: visitor, visited: visited, review: review)
        expect(notification).to be_valid
      end

      it 'コメントの通知が有効であること' do
        notification = build(:notification, :for_comment, visitor: visitor, visited: visited, comment: comment)
        expect(notification).to be_valid
      end
    end

    context '異常系' do
      it 'visitor_id がない場合は無効であること' do
        notification = build(:notification, :for_like, visitor: nil, visited: visited, review: review)
        expect(notification).not_to be_valid
        expect(notification.errors.full_messages).to include("Visitorを入力してください")
      end

      it 'visited_id がない場合は無効であること' do
        notification = build(:notification, :for_like, visitor: visitor, visited: nil, review: review)
        expect(notification).not_to be_valid
        expect(notification.errors.full_messages).to include("Visitedを入力してください")
      end

      it 'action がない場合は無効であること' do
        notification = build(:notification, visitor: visitor, visited: visited, action: nil, review: review)
        expect(notification).not_to be_valid
        expect(notification.errors.full_messages).to include("ActionActionを入力してください")
      end

      it 'action が comment の場合、comment が nil なら無効であること' do
        notification = build(:notification, :for_comment, visitor: visitor, visited: visited, comment: nil)
        expect(notification).not_to be_valid
      end
    end
  end
end
