class Admin::ItemsController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    @items = Item.all
  end

  def edit
    @item = Item.find(params[:id])
  end

  def update
    @item = Item.find(params[:id])
    if @item.update(item_params)
      redirect_to admin_items_path, notice: "商品情報を更新しました。"
    else
      render :edit, alert: "更新に失敗しました。"
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :manufacturer, :price, :amazon_url, :asin)
  end

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です。"
    end
  end
end
