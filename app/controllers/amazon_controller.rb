class AmazonController < ApplicationController
  # Amazonの商品検索結果を返す
  def index
    # 5文字未満 or 201文字以上 or 空白の場合は検索しない(リクエストを無駄にしないため)
    query = params[:q].to_s.strip
    return render plain: "", status: :ok if query.blank? || query.size < 6 || query.size > 200

    # Amazon APIを使って商品検索
    amazon = AmazonApiClient.new
    response = amazon.search_items(params[:q])

    # 商品リストを取り出す（無ければ空配列）
    items = response.dig("SearchResult", "Items") || []

    # 必要な情報だけ取り出して、配列に詰める
    @items = items.filter_map do |item|
      title = item.dig("ItemInfo", "Title", "DisplayValue")
      asin  = item["ASIN"]
      image_url = item.dig("Images", "Primary", "Large", "URL")

      # タイトルかASINが空なら次の商品へ
      next if title.blank? || asin.blank?

      # タイトル、ASIN、画像URLをハッシュで返す
      {
        id:   asin,
        name: title,
        image_url: image_url
      }
    end

    # レイアウト無しでHTMLを返す（autocomplete用）
    render layout: false
  rescue => e
    logger.error "[AmazonAutocompleteError] #{e.message}"
    render plain: "エラーが発生しました", status: :internal_server_error
  end
end
