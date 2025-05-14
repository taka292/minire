module ApplicationHelper
  def default_meta_tags
    {
      site: "MiniRe (ミニレ)",
      title: "ミニマリスト向けレビューサイト",
      reverse: true,
      charset: "utf-8",
      description: "探さない、迷わない。MiniReがあるから。MiniReは、ミニマリストやシンプルライフを目指す人向けのレビューサイトです。厳選されたアイテムのレビューを参考に、少ないモノで豊かに暮らすヒントを見つけましょう。",
      keywords: "ミニマリスト, シンプルライフ, 持たない暮らし, 愛用品, レビュー, アイテム, 最小限, MiniRe",
      canonical: request.original_url,
      separator: "|",
      og: {
        site_name: "MiniRe (ミニレ)",
        title: content_for(:og_title) || "ミニマリスト向けレビューサイト",
        description: content_for(:og_description) || "探さない、迷わない。MiniReがあるから。",
        type: "website",
        url: request.original_url,
        image: content_for(:og_image) || image_url("ogp.png"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@MiniRe_minimal",
        image: content_for(:og_image) || image_url("ogp.png")
      }
    }
  end

  # フォームでエラーになった箇所を赤く囲む
  def error_class(resource, attribute)
    resource.errors[attribute].present? ? "border-red-500" : ""
  end

  # Ransackで使うデフォルト検索項目
  def review_search_field
    :title_or_content_or_item_name_or_item_description_or_item_asin_or_item_manufacturer_or_releasable_items_name_cont
  end
end
