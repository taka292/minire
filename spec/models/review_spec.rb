require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:valid_review) { build(:review) }

  describe 'バリデーション' do
    it '有効なデータがあれば保存できる' do
      expect(valid_review).to be_valid
    end

    it 'タイトルが空だと無効' do
      valid_review.title = nil
      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:title]).to include("タイトルを入力してください")
    end

    it 'タイトルが101文字以上だと無効' do
      valid_review.title = "a" * 101
      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:title]).to include("100文字以内で入力してください")
    end

    it 'コンテンツが空だと無効' do
      valid_review.content = nil
      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:content]).to include("内容を入力してください")
    end

    it 'コンテンツが1001文字以上だと無効' do
      valid_review.content = "a" * 1001
      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:content]).to include("1000文字以内で入力してください")
    end

    it 'タイトルとコンテンツが適切な文字数以内なら有効' do
      valid_review.title = "a" * 100
      valid_review.content = "a" * 1000
      expect(valid_review).to be_valid
    end

    it 'アップロード画像が不正な形式の場合無効' do
      invalid_image = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("invalid data"),
        filename: "invalid.txt",
        content_type: "text/plain"
      )

      valid_review.images.attach(invalid_image)
      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:images]).to include("JPEG, PNG, GIF形式のみアップロードできます")
    end

    it 'ユーザーが関連付けられていない場合は無効' do
      valid_review.user = nil
      expect(valid_review).not_to be_valid
    end

    it 'アップロード画像が許容枚数を超えた場合無効' do
      6.times do
        valid_review.images.attach(
          io: StringIO.new("image data"),
          filename: "image.jpg",
          content_type: "image/jpeg"
        )
      end

      expect(valid_review).not_to be_valid
      expect(valid_review.errors[:images]).to include("5枚以下でアップロードしてください")
    end
  end
end
