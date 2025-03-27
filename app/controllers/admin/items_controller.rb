class Admin::ItemsController < ApplicationController
  require "open-uri"
  before_action :authenticate_admin!

  def index
    @items = Item.all
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
    item = Item.find(params[:id])
    return redirect_to edit_admin_item_path(item), alert: "ASINが登録されていません" if item.asin.blank?

    client = AmazonApiClient.new
    response = client.get_item_by_asin(item.asin)
    amazon_item = response.dig("ItemsResult", "Items")&.first

    if amazon_item.blank?
      return redirect_to edit_admin_item_path(item), alert: "Amazonから情報を取得できませんでした"
    end

    # Primary画像（Large → Medium → Small の順で優先）
    primary_image_url = amazon_item.dig("Images", "Primary", "Large", "URL") ||
                        amazon_item.dig("Images", "Primary", "Medium", "URL") ||
                        amazon_item.dig("Images", "Primary", "Small", "URL")

    # Variants画像（複数ある可能性あり）
    variant_images = amazon_item.dig("Images", "Variants") || []

    variant_urls = variant_images.map do |variant|
      variant.dig("Large", "URL") ||
      variant.dig("Medium", "URL") ||
      variant.dig("Small", "URL")
    end.compact.uniq

    # primary と重複していたら除外
    variant_urls.reject! { |url| url == primary_image_url }

    begin
      # 1. メイン画像を最初に保存
      if primary_image_url.present?
        downloaded_image = URI.open(primary_image_url)
        item.images.attach(io: downloaded_image, filename: File.basename(URI.parse(primary_image_url).path))
      end

      # 2. バリエーション画像を後から保存
      variant_urls.each do |url|
        downloaded_image = URI.open(url)
        item.images.attach(io: downloaded_image, filename: File.basename(URI.parse(url).path))
      end
    rescue => e
      Rails.logger.error "[AmazonAPI] 商品画像の保存に失敗: #{e.message}"
    end

    item.update(
      manufacturer: amazon_item.dig("ItemInfo", "ByLineInfo", "Manufacturer", "DisplayValue"),
      price:        amazon_item.dig("Offers", "Listings", 0, "Price", "Amount").to_i,
      description:  (amazon_item.dig("ItemInfo", "Features", "DisplayValues") || []).join("\n"),
      amazon_url:   amazon_item["DetailPageURL"],
      last_updated_at: Time.current
    )

    redirect_to edit_admin_item_path(item), notice: "Amazon情報を更新しました"
  end

  private

  def item_params
    params.require(:item).permit(:name, :manufacturer, :price, :amazon_url, :asin, :description, images: [], remove_images: [])
  end

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です。"
    end
  end
end
