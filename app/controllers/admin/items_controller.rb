class Admin::ItemsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @items = Item.order(created_at: :desc)
  end

  def edit
    @item = Item.find(params[:id])
  end
  # 削除対象の画像が指定されていれば削除
  def update
    @item = Item.find(params[:id])

    # 削除対象の画像が指定されている場合のみ削除
    if params[:item][:remove_images].present?
      params[:item][:remove_images].each do |image_id|
        image = @item.images.find_by(blob_id: image_id)
        image&.purge # 該当画像のみ削除
      end
    end

    # 新しい画像をアップロードし、既存画像を保持
    if params[:item][:images].present?
      params[:item][:images].each do |image|
        @item.images.attach(image)
      end
    end

    # その他のフィールドを更新
    if @item.update(item_params.except(:images, :remove_images))
      redirect_to admin_item_path(@item), notice: "商品情報を更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit
    end
  end

  def fetch_amazon_info
    item = AmazonItemImporter.new(params[:asin] || Item.find(params[:id]).asin).import!
    if item
      redirect_to edit_admin_item_path(item), notice: "Amazon情報を更新しました"
    else
      redirect_to edit_admin_item_path(item || Item.find(params[:id])), alert: "Amazonから情報を取得できませんでした"
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :manufacturer, :price, :amazon_url, :asin, :description, :category_id,  images: [], remove_images: [])
  end

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です。"
    end
  end
end
