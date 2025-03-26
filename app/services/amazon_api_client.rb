require "uri"
require "net/http"
require "openssl"
require "base64"
require "json"

class AmazonApiClient
  attr_reader :access_key, :secret_key, :partner_tag, :region, :service, :host

  def initialize
    @access_key = ENV["AWS_ACCESS_KEY_ID"]
    @secret_key = ENV["AWS_SECRET_ACCESS_KEY"]
    @partner_tag = ENV["PARTNER_TAG"]
    @region = "us-west-2"
    @service = "ProductAdvertisingAPI"
    @host = "webservices.amazon.co.jp"
  end

  # レビュー時の商品検索
  def search_items(keywords)
    payload = {
      "Keywords": keywords,
      "PartnerTag": partner_tag,
      "PartnerType": "Associates",
      "Marketplace": "www.amazon.co.jp",
      "Resources": [
        "ItemInfo.Title",
        "Images.Primary.Medium",
        "ItemInfo.ByLineInfo",
        "Offers.Listings.Price"
      ]
    }.to_json

    uri = URI("https://#{host}/paapi5/searchitems")

    headers = signed_headers(uri, payload, "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.SearchItems")


    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    headers.each { |k, v| request[k] = v }
    request.body = payload

    response = http.request(request)
    JSON.parse(response.body)
  end

  # ASINを指定して商品情報を取得
  def get_item_by_asin(asin)
    payload = {
      "ItemIds": [asin],
      "Resources": [
        "ItemInfo.Title",
        "Images.Primary.Medium",
        "ItemInfo.ByLineInfo",
        "ItemInfo.Features",
        "Offers.Listings.Price"
      ],
      "PartnerTag": partner_tag,
      "PartnerType": "Associates",
      "Marketplace": "www.amazon.co.jp"
    }.to_json

    uri = URI("https://#{host}/paapi5/getitems")

    headers = signed_headers(uri, payload, "com.amazon.paapi5.v1.ProductAdvertisingAPIv1.GetItems")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    headers.each { |k, v| request[k] = v }
    request.body = payload

    response = http.request(request)
    JSON.parse(response.body)
  end


  private

  def signed_headers(uri, payload, target)
    t = Time.now.utc
    amz_date = t.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = t.strftime("%Y%m%d")

    canonical_uri = uri.path
    canonical_querystring = ""

    headers = {
      "content-encoding" => "amz-1.0",
      "content-type" => "application/json; charset=utf-8",
      "host" => host,
      "x-amz-date" => amz_date,
      "x-amz-target" => target
    }

    canonical_headers = headers.sort.map { |k, v| "#{k}:#{v}" }.join("\n") + "\n"
    signed_headers = headers.keys.sort.join(";")
    payload_hash = Digest::SHA256.hexdigest(payload)

    canonical_request = [
      "POST",
      canonical_uri,
      canonical_querystring,
      canonical_headers,
      signed_headers,
      payload_hash
    ].join("\n")

    algorithm = "AWS4-HMAC-SHA256"
    credential_scope = "#{date_stamp}/#{region}/#{service}/aws4_request"
    string_to_sign = [
      algorithm,
      amz_date,
      credential_scope,
      Digest::SHA256.hexdigest(canonical_request)
    ].join("\n")

    signing_key = get_signature_key(secret_key, date_stamp, region, service)
    signature = OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)

    authorization_header = [
      "#{algorithm} Credential=#{access_key}/#{credential_scope}",
      "SignedHeaders=#{signed_headers}",
      "Signature=#{signature}"
    ].join(", ")

    headers.merge({ "Authorization" => authorization_header })
  end



  def get_signature_key(key, date_stamp, region_name, service_name)
    k_date = hmac("AWS4" + key, date_stamp)
    k_region = hmac(k_date, region_name)
    k_service = hmac(k_region, service_name)
    hmac(k_service, "aws4_request")
  end

  def hmac(key, data)
    OpenSSL::HMAC.digest("sha256", key, data)
  end
end
