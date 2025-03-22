# app/controllers/amazon_controller.rb
class AmazonController < ApplicationController
  require 'ostruct' # 🔸 これが必要！

  def index
    query = params[:q]
    return render plain: "", status: :ok if query.blank?

    amazon = AmazonTransfer.new
    response = amazon.search_items(query)

    items = response["SearchResult"]&.dig("Items") || []

    @items = items.map do |item|
      title = item.dig("ItemInfo", "Title", "DisplayValue")
      asin = item["ASIN"]

      next if title.blank? || asin.blank?

      OpenStruct.new(id: asin, name: title)
    end.compact # 🔸 nil を除く

    respond_to do |format|
      format.js # views/amazon/index.html.erb を表示
    end
  rescue StandardError => e
    logger.error "[AmazonAutocompleteError] #{e.message}"
    render plain: "エラーが発生しました", status: :internal_server_error
  end
end
