class ItemsController < ApplicationController
  def index
    @items = Item.where("name LIKE ?", "%#{params[:q]}%")
    respond_to do |format|
      format.js
    end
  end

  def show
    @item = Item.includes(:reviews).find_by(id: params[:id])
    if @item.nil?
      redirect_to items_path, alert: "該当の商品が見つかりません。"
    else
      @reviews = @item.reviews
    end
  end
end
