class ItemsController < ApplicationController
  def index
    @items = Item.where("name LIKE ?", "%#{params[:q]}%")
    respond_to do |format|
      format.js
    end
  end
end
