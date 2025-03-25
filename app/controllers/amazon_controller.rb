class AmazonController < ApplicationController
  # Amazonの商品検索結果を返す
  def index
    # 検索ワード（q）が空なら空レスポンスを返す
    return render plain: "", status: :ok if params[:q].blank?

    # Amazon APIを使って商品検索
    amazon = AmazonTransfer.new
    response = amazon.search_items(params[:q])

    # 商品リストを取り出す（無ければ空配列）
    items = response.dig("SearchResult", "Items") || []

    # 必要な情報だけ取り出して、配列に詰める
    @items = items.filter_map do |item|
      title = item.dig("ItemInfo", "Title", "DisplayValue")
      asin  = item["ASIN"]
      image_url = item.dig("Images", "Primary", "Medium", "URL")

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
