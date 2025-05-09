class Admin::CategoriesController < ApplicationController
  def index
    @categories = Category.ordered
  end

  def move_higher
    Category.find(params[:id]).move_higher
    redirect_to admin_categories_path
  end

  def move_lower
    Category.find(params[:id]).move_lower
    redirect_to admin_categories_path
  end
end
