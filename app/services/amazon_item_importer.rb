require "open-uri"

# AmazonのASINをもとに、商品情報（Itemモデル）を取得・保存するためのサービスクラス
class AmazonItemImporter
  def initialize(asin)
    @asin = asin
    @client = AmazonApiClient.new  # Amazon APIにアクセスするクライアントを初期化
  end

  # 商品情報の取得・保存を実行するメイン処理
  def import!
    response = @client.get_item_by_asin(@asin) # 指定されたASINの商品情報をAmazon APIから取得
    amazon_item = response.dig("ItemsResult", "Items")&.first # 最初の1件の商品情報を取り出す
    return nil if amazon_item.blank? # データがなければ処理を中断

    # 既に同じASINのItemがあれば取得、なければ新規作成
    item = Item.find_or_initialize_by(asin: @asin)

    # メイン画像のURLを取得（大→中→小の優先順で取得）
    primary_image_url = amazon_item.dig("Images", "Primary", "Large", "URL") ||
                        amazon_item.dig("Images", "Primary", "Medium", "URL") ||
                        amazon_item.dig("Images", "Primary", "Small", "URL")

    # バリエーション画像（複数）を配列で取得し、URLの重複を除去
    variant_urls = (amazon_item.dig("Images", "Variants") || []).map do |variant|
      variant.dig("Large", "URL") ||
      variant.dig("Medium", "URL") ||
      variant.dig("Small", "URL")
    end.compact.uniq

    # メイン画像と同じURLのバリエーション画像は除外
    variant_urls.reject! { |url| url == primary_image_url }

    # 画像をItemに添付（メイン画像＋バリエーション画像）
    attach_images(item, primary_image_url, variant_urls)

    # 商品情報をItemモデルにセット（まだ保存はしない）
    item.assign_attributes(
      name:         amazon_item.dig("ItemInfo", "Title", "DisplayValue"),             # 商品名
      manufacturer: amazon_item.dig("ItemInfo", "ByLineInfo", "Manufacturer", "DisplayValue"), # メーカー名
      price:        amazon_item.dig("Offers", "Listings", 0, "Price", "Amount").to_i, # 価格（整数）
      description:  (amazon_item.dig("ItemInfo", "Features", "DisplayValues") || []).join("\n").truncate(500), # 特徴を改行区切りで結合して500文字以内に制限
      amazon_url:   amazon_item["DetailPageURL"],                                     # 商品ページのURL
      last_updated_at: Time.current                                                   # 最終更新日時を現在時刻で記録
    )

    # Amazonのカテゴリ情報を元に、Itemのカテゴリを設定する処理
    # 1. ルートカテゴリを取得
    root_category = extract_root_browse_node(amazon_item)

    # 2. マッピングされたカテゴリ名を取得（対応表にある場合）
    mapped_name = root_category.present? ? AMAZON_ROOT_CATEGORY_MAP[root_category[:id]] : nil

    # 3. 実際の Category モデルを取得
    mapped_category = mapped_name.present? ? Category.find_by(name: mapped_name) : nil

    # 4. item にカテゴリをセット（マッピングが見つかればそれを、なければ「その他」）
    item.category = mapped_category || Category.find_by(name: "その他")

    item.save! # Itemを保存（バリデーション失敗時は例外が発生）

    item # 最終的に保存したItemを返す
  rescue => e
    # 何らかのエラーが発生した場合はログに出力してnilを返す
    Rails.logger.error "[AmazonItemImporter] 失敗: #{e.message}"
    nil
  end

  private

  # 画像をItemに添付する処理（ActiveStorageを利用）
  def attach_images(item, primary_url, variant_urls)
    return unless item.images.blank? # すでに画像がある場合はスキップ

    # メイン画像をダウンロードして添付
    if primary_url.present?
      downloaded = URI.open(primary_url)
      item.images.attach(io: downloaded, filename: File.basename(URI.parse(primary_url).path))
    end

    # バリエーション画像を順に添付
    variant_urls.each do |url|
      downloaded = URI.open(url)
      item.images.attach(io: downloaded, filename: File.basename(URI.parse(url).path))
    end
  rescue => e
    # ダウンロードや添付中にエラーがあった場合はログに記録
    Rails.logger.error "[AmazonItemImporter] 画像保存失敗: #{e.message}"
  end

  # AmazonのBrowseNode情報から最親のカテゴリを抽出する処理
  def extract_root_browse_node(amazon_item)
    browse_nodes = amazon_item.dig("BrowseNodeInfo", "BrowseNodes") || []

    browse_nodes.map do |node|
      current = node
      current = current["Ancestor"] while current["Ancestor"].present?
      {
        id: current["Id"],
        name: current["DisplayName"]
      }
    end.uniq.first
  end
end
