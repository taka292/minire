class ReviewItemAssignmentService
  def initialize(review, params)
    @review = review
    @params = params
  end

  # 商品情報をパラメータに基づいて取得・作成し、レビューに関連付ける
  # 処理失敗時はエラーを追加して false を返す
  def call
    item = case @params[:search_method] # Amazonまたはサイト内検索に応じてItemを取得・登録
    when "amazon"    # Amazon検索・登録
      assign_amazon_item
    when "minire"    # サイト内検索・登録
      assign_minire_item
    else
      # 想定外の search_method の場合のエラー
      return error!(:item_name, "商品名を入力してください")
    end

    # 商品情報が不完全（例：名前がない）場合は付与したエラーメッセージをもとにエラーを返す
    return false unless item

    # 商品情報を保存（新規作成または更新ありの場合）
    if item.new_record? || item.has_changes_to_save?
      unless item.save
        return error!(:item_name, item.errors.full_messages.join(", "))
      end
    end

    # 商品をレビューに関連付け
    @review.item = item
    true
  end

  private

  # Amazon検索で選択された ASIN に対応する商品を取得・作成
  def assign_amazon_item
    asin = @params[:asin]&.strip                    # Amazonの商品コード（ASIN）
    item_name = @params[:amazon_item_name]&.strip  # Amazon検索候補で選択された商品名

    # Amazonの商品が選択されていない場合はエラー
    if asin.blank? || item_name.blank?
      return error!(:amazon_item_name, "Amazonの商品を選択してください")
    end

    # ASINをもとに、必要に応じてAPIで商品情報を取得・作成
    item = fetch_amazon_info_if_needed(Item.find_or_initialize_by(asin: asin))

    # 商品情報が不完全（例：名前がない）場合はエラー
    if item.name.blank?
      return error!(:amazon_item_name, "商品情報の取得に失敗しました。もう一度お試しください")
    end

    item
  end

  # MiniRe内の検索・商品名入力に基づく商品を取得・作成
  def assign_minire_item
    item_name = @params[:item_name]&.strip  # サイト内検索で指定された商品名

    # 商品名が空の場合はエラー
    if item_name.blank?
      return error!(:item_name, "商品名を入力してください")
    end

    # 名前から商品を初期化し、カテゴリ未設定であれば「その他」に設定
    Item.find_or_initialize_by(name: item_name).tap do |i|
      i.category ||= Category.find_by(name: "その他")
    end
  end

  # Amazon APIから商品情報取得
  def fetch_amazon_info_if_needed(item)
    # Amazon検索で取得したItemのasinが存在し、まだ一度も更新されていない場合のみ、Amazon APIから商品情報取得
    if item.asin.present? && item.last_updated_at.blank?
      imported_item = AmazonItemImporter.new(item.asin).import!
      return imported_item || item
    end
    # 既に登録済みであればDBから取得した情報を返す
    item
  end

  # レビューにエラーメッセージを追加し false を返す共通処理
  def error!(attr, message)
    @review.errors.add(attr, message)
    false
  end
end
