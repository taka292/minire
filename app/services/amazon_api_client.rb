require "uri"
require "net/http"
require "json"
require "aws-sigv4"

class AmazonApiClient
  attr_reader :access_key, :secret_key, :partner_tag, :region, :service, :host

  def initialize
    # 環境変数から認証情報・Amazon APIに必要な基本情報を取得
    @access_key = ENV["AMAZON_API_ACCESS_KEY"]
    @secret_key = ENV["AMAZON_API_SECRET_KEY"]
    @partner_tag = ENV["AMAZON_API_PARTNER_TAG"]
    @region = "us-west-2"
    @service = "ProductAdvertisingAPI"
    @host = "webservices.amazon.co.jp"
  end

  # キーワードをもとにAmazon商品を検索する処理
  def search_items(keywords)
    # 検索用のリクエストボディ（取得したい情報と検索キーワード）を構築
    payload = {
      "Keywords" => keywords,
      "PartnerTag" => partner_tag,
      "PartnerType" => "Associates",
      "Marketplace" => "www.amazon.co.jp",
      "Resources" => [
        "ItemInfo.Title",
        "Images.Primary.Large",
        "ItemInfo.ByLineInfo",
        "Offers.Listings.Price"
      ]
    }

    # 共通処理メソッドを使ってAPIリクエストを送信
    post_to_amazon_api(
      path: "/paapi5/searchitems", # 検索用エンドポイント
      target: "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems", # APIターゲット名
      payload: payload
    )
  end

  # ASIN（商品ID）をもとに1件の商品情報を取得する処理
  def get_item_by_asin(asin)
    # 商品ID（ASIN）を指定して取得したい情報をリクエストボディに含める
    payload = {
      "ItemIds" => [ asin ],
      "PartnerTag" => partner_tag,
      "PartnerType" => "Associates",
      "Marketplace" => "www.amazon.co.jp",
      "Resources" => [
        "ItemInfo.Title",
        "Images.Primary.Large",
        "Images.Variants.Large",
        "ItemInfo.ByLineInfo",
        "ItemInfo.Features",
        "Offers.Listings.Price",
        # 商品カテゴリ情報
        "BrowseNodeInfo.BrowseNodes.Ancestor"
      ]
    }

    # 共通処理メソッドを使ってAPIリクエストを送信
    post_to_amazon_api(
      path: "/paapi5/getitems", # 商品取得用エンドポイント
      target: "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.GetItems", # APIターゲット名
      payload: payload
    )
  end

  private

  # Amazon APIにPOSTリクエストを送信するメソッド
  def post_to_amazon_api(path:, target:, payload:)
    # JSON形式に変換
    payload_json = payload.to_json
    # リクエストURIを構築
    uri = URI("https://#{host}#{path}")

    # 署名に使用するためのヘッダーを事前に定義
    headers = {
      "host" => host,
      "content-type" => "application/json; charset=utf-8",
      "x-amz-target" => target,
      "content-encoding" => "amz-1.0"
    }

    # AWS Signature Version 4を使用してリクエストに署名するための設定
    signer = Aws::Sigv4::Signer.new(
      service: service,
      region: region,
      access_key_id: access_key,
      secret_access_key: secret_key
    )

    # リクエストの署名を生成
    signature = signer.sign_request(
      http_method: "POST",
      url: uri.to_s,
      headers: headers,
      body: payload_json
    )

    # リクエストオブジェクトを生成
    request = Net::HTTP::Post.new(uri)

    # 署名前のヘッダーをrequestに反映(署名後のヘッダーからは抜け落ちてしまう)
    headers.each { |k, v| request[k] = v }

    # 署名後に生成されたヘッダーをrequestに反映
    request["authorization"] = signature.headers["authorization"]
    request["x-amz-date"] = signature.headers["x-amz-date"]
    request["x-amz-content-sha256"] = signature.headers["x-amz-content-sha256"]

    # リクエストボディをJSON形式に変換してセット
    request.body = payload_json

    # HTTP通信の準備
    http = Net::HTTP.new(uri.host, uri.port)
    # HTTPSを使用
    http.use_ssl = true

    # 実際にリクエストを送信
    response = http.request(request)
    # レスポンスをJSONとして返す
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("[AmazonApiClient] リクエスト失敗: #{e.class} - #{e.message}")
  end
end
