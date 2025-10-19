class ItemsController < ApplicationController
  def index
    return redirect_to root_path unless params[:q].present?
    
    @items = Item.where("name LIKE ?", "%#{params[:q]}%")
    render layout: false
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
