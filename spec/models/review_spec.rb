require 'rails_helper'

RSpec.describe Review, type: :model do
  let(:user) { User.create(email: "test@example.com", password: "password") }

  it "有効なデータがあれば保存できる" do
    review = Review.new(title: "タイトル", content: "内容", user: user)
    expect(review).to be_valid
  end

  it "タイトルが空だと無効" do
    review = Review.new(title: nil, content: "内容", user: user)
    expect(review).not_to be_valid
    expect(review.errors[:title]).to include("タイトルを入力してください")
  end

  it "タイトルが101文字以上だと無効" do
    review = Review.new(title: "a" * 101, content: "内容", user: user)
    expect(review).not_to be_valid
    expect(review.errors[:title]).to include("は100文字以内で入力してください")
  end

  it "コンテンツが空だと無効" do
    review = Review.new(title: "タイトル", content: nil, user: user)
    expect(review).not_to be_valid
    expect(review.errors[:content]).to include("内容を入力してください")
  end

  it "コンテンツが1001文字以上だと無効" do
    review = Review.new(title: "タイトル", content: "a" * 1001, user: user)
    expect(review).not_to be_valid
    expect(review.errors[:content]).to include("は1000文字以内で入力してください")
  end

  it "タイトルとコンテンツが適切な文字数以内なら有効" do
    review = Review.new(title: "a" * 100, content: "a" * 1000, user: user)
    expect(review).to be_valid
  end

  it "アップロード画像が不正な形式の場合無効" do
    invalid_image = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("invalid data"),
      filename: "invalid.txt",
      content_type: "text/plain"
    )

    review = Review.new(title: "タイトル", content: "内容", user: user)
    review.images.attach(invalid_image)
    expect(review).not_to be_valid
    expect(review.errors[:images]).to include("はJPEG, PNG, GIF形式のみアップロードできます")
  end

  it "ユーザーが関連付けられていない場合は無効" do
    review = Review.new(title: "タイトル", content: "内容", user: nil)
    expect(review).not_to be_valid
  end

  it "アップロード画像が許容枚数を超えた場合無効" do
    review = Review.new(title: "タイトル", content: "内容", user: user)

    # 許容枚数を超える画像を添付
    6.times do
      review.images.attach(
        io: StringIO.new("image data"),
        filename: "image.jpg",
        content_type: "image/jpeg"
      )
    end

    expect(review).not_to be_valid
    expect(review.errors[:images]).to include("は5枚以下でアップロードしてください")
  end
end
