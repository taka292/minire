require 'rails_helper'

RSpec.describe "Reviews", type: :request do
  let(:user) { create(:user) }
  let!(:review) { create(:review, user: user) }

  before do
    sign_in user
  end

  it "ログインユーザーが存在している" do
    expect(User.find_by(email: user.email)).to eq(user)
  end

  it "認証された状態でレビュー一覧にアクセスできる" do
    get reviews_path
    expect(response).to have_http_status(200) # 認証が成功している場合
  end

  describe "GET /reviews" do
    it "全てのレビューを表示し、ステータス200を返す" do
      get reviews_path
      expect(response).to have_http_status(200)
      expect(response.body).to include(review.title)
    end
  end

  describe "GET /reviews/:id" do
    it "特定のレビューを表示し、ステータス200を返す" do
      get review_path(review)
      expect(response).to have_http_status(200)
      expect(response.body).to include(review.content)
    end
  end

  describe "GET /reviews/new" do
    it "新規作成ページを表示し、ステータス200を返す" do
      get new_review_path
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /reviews" do
    context "有効なパラメータの場合" do
      let(:valid_params) { attributes_for(:review) }

      it "レビューを作成し、リダイレクトする" do
        expect {
          post reviews_path, params: { review: valid_params }
        }.to change(Review, :count).by(1)
        expect(response).to redirect_to(review_path(Review.last))
      end
    end

    context "無効なパラメータの場合" do
      let(:invalid_params) { attributes_for(:review, title: nil) }

      it "新規作成ページを再表示する" do
        expect {
          post reviews_path, params: { review: invalid_params }
        }.not_to change(Review, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH /reviews/:id" do
    context "有効なパラメータの場合" do
      let(:new_attributes) { { title: "更新後のタイトル", content: "更新後の内容" } }

      it "レビューを更新し、リダイレクトする" do
        patch review_path(review), params: { review: new_attributes }
        review.reload
        expect(review.title).to eq("更新後のタイトル")
        expect(review.content).to eq("更新後の内容")
        expect(response).to redirect_to(review_path(review))
      end
    end

    context "無効なパラメータの場合" do
      let(:invalid_attributes) { { title: nil } }

      it "編集ページを再表示する" do
        patch review_path(review), params: { review: invalid_attributes }
        review.reload
        expect(review.title).not_to eq(nil)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE /reviews/:id" do
    it "レビューを削除し、リダイレクトする" do
      expect {
        delete review_path(review)
      }.to change(Review, :count).by(-1)
      expect(response).to redirect_to(reviews_path)
    end
  end
end
