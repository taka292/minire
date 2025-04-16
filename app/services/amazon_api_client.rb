require "uri"
require "net/http"
require "openssl"
require "base64"
require "json"

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
      "Keywords": keywords,
      "PartnerTag": partner_tag,
      "PartnerType": "Associates",
      "Marketplace": "www.amazon.co.jp",
      "Resources": [
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
      "ItemIds": [ asin ],
      "PartnerTag": partner_tag,
      "PartnerType": "Associates",
      "Marketplace": "www.amazon.co.jp",
      "Resources": [
        "ItemInfo.Title",
        "Images.Primary.Large",
        "Images.Variants.Large",
        "ItemInfo.ByLineInfo",
        "ItemInfo.Features",
        "Offers.Listings.Price"
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

  # Amazon PA-APIの仕様に沿って署名付きヘッダーを作成
  def signed_headers(uri, payload, target)
    # 現在時刻をUTC形式で取得（署名に使用）
    t = Time.now.utc
    amz_date = t.strftime("%Y%m%dT%H%M%SZ")  # 例: 20250414T120000Z
    date_stamp = t.strftime("%Y%m%d")        # 例: 20250414

    canonical_uri = uri.path                 # パス（例: /paapi5/searchitems）
    canonical_querystring = ""              # クエリなし（空文字）

    # Amazonに送信するリクエストヘッダー（アルファベット順に並べる必要あり）
    headers = {
      "content-encoding" => "amz-1.0",
      "content-type" => "application/json; charset=utf-8",
      "host" => host,
      "x-amz-date" => amz_date,
      "x-amz-target" => target
    }

    # Canonical Headers：key:value 形式でヘッダーを並べた文字列（改行区切り）
    canonical_headers = headers.sort.map { |k, v| "#{k}:#{v}" }.join("\n") + "\n"

    # Signed Headers：署名対象とするヘッダーの名前をセミコロンで連結（アルファベット順）
    signed_headers = headers.keys.sort.join(";")

    # ペイロード（ボディ）のSHA256ハッシュ値を計算
    payload_hash = Digest::SHA256.hexdigest(payload)

    # Canonical Requestを構築（署名の材料）
    canonical_request = [
      "POST",
      canonical_uri,
      canonical_querystring,
      canonical_headers,
      signed_headers,
      payload_hash
    ].join("\n")

    # String to Sign：署名対象の最終文字列
    algorithm = "AWS4-HMAC-SHA256"
    credential_scope = "#{date_stamp}/#{region}/#{service}/aws4_request"
    string_to_sign = [
      algorithm,
      amz_date,
      credential_scope,
      Digest::SHA256.hexdigest(canonical_request)
    ].join("\n")

    # 秘密鍵と日付・サービス名などを元に署名鍵を作成
    signing_key = get_signature_key(secret_key, date_stamp, region, service)

    # 署名（Signature）を生成
    signature = OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)

    # Authorization ヘッダーを作成（最終的にAmazonへ送る認証情報）
    authorization_header = [
      "#{algorithm} Credential=#{access_key}/#{credential_scope}",
      "SignedHeaders=#{signed_headers}",
      "Signature=#{signature}"
    ].join(", ")

    # Authorizationを含む全ヘッダーを返却
    headers.merge({ "Authorization" => authorization_header })
  end

  # AWS署名v4に基づく署名鍵の作成（4段階のHMAC）
  def get_signature_key(key, date_stamp, region_name, service_name)
    k_date = hmac("AWS4" + key, date_stamp)
    k_region = hmac(k_date, region_name)
    k_service = hmac(k_region, service_name)
    hmac(k_service, "aws4_request")
  end

  # HMAC署名を1回行う処理（秘密鍵 + データ → SHA256ダイジェスト）
  def hmac(key, data)
    OpenSSL::HMAC.digest("sha256", key, data)
  end

  # Amazon APIにPOSTリクエストを送信するメソッド
  def post_to_amazon_api(path:, target:, payload:)
    payload_json = payload.to_json                            # JSON形式に変換
    uri = URI("https://#{host}#{path}")                       # URIオブジェクトを作成
    headers = signed_headers(uri, payload_json, target)       # 署名付きのヘッダーを生成

    # HTTP通信の準備
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true                                       # HTTPSを使用

    # POSTリクエストの作成と送信
    request = Net::HTTP::Post.new(uri)
    headers.each { |k, v| request[k] = v }                     # ヘッダーをセット
    request.body = payload_json                               # リクエストボディをセット

    response = http.request(request)                          # 実際にリクエストを送信
    JSON.parse(response.body)                                 # レスポンスをJSONとして返す
  end
end
