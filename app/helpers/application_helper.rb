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
        title: "ミニマリスト向けレビューサイト",
        description: "探さない、迷わない。MiniReがあるから。MiniReは、ミニマリストやシンプルライフを目指す人向けのレビューサイトです。",
        type: "website",
        url: request.original_url,
        image: image_url("ogp.png"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@MiniRe_minimal",
        image: image_url("ogp.png")
      }
    }
  end

  def error_class(resource, attribute)
    resource.errors[attribute].present? ? "border-red-500" : ""
  end
end
