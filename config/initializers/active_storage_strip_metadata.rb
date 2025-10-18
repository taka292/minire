# frozen_string_literal: true

# 【このファイルの役割】
# すべての画像 variant から位置情報などのメタデータ(EXIF)を自動的に削除します。
# プライバシー保護のため、アップロードされた画像から GPS 情報などを除去します。
#
# 対象: すべての image.variant(...) 呼び出し
# 効果: 自動的に saver: { strip: true } が追加される
#
# 例:
#   image.variant(resize_to_limit: [600, 600])
#   ↓ 内部的に以下のように変換される
#   image.variant(resize_to_limit: [600, 600], saver: { strip: true })
#
# 削除されるメタ情報:
#   - GPS位置情報（緯度・経度）
#   - 撮影日時
#   - カメラのメーカー・機種
#   - カメラ設定（ISO感度、シャッター速度、絞り値など）
#   - その他のEXIFタグすべて

Rails.application.config.after_initialize do
  # メタ情報削除用のモジュール
  module ActiveStorageStripMetadata
    def variant(transformations)
      # transformations が Hash の場合のみ処理
      if transformations.is_a?(Hash)
        # 元のハッシュを変更しないように複製
        transformations = transformations.dup
        # ネストした :saver も複製して可変にする
        transformations[:saver] = (transformations[:saver] || {}).dup
        transformations[:saver][:strip] = true
      end
      # 元の variant メソッドを呼び出し
      super(transformations)
    end
  end

  # ActiveStorage::Blob::Representable にモジュールを prepend
  # prepend を使うことで、元のメソッドを super で呼び出せる
  ActiveStorage::Blob::Representable.prepend(ActiveStorageStripMetadata)
end

