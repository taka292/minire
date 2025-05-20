class AddTrgmIndexesForSearch < ActiveRecord::Migration[7.2]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    # reviews
    execute "CREATE INDEX index_reviews_on_title_trgm ON reviews USING gin (title gin_trgm_ops)" unless index_exists?(:reviews, :title, name: "index_reviews_on_title_trgm")
    execute "CREATE INDEX index_reviews_on_content_trgm ON reviews USING gin (content gin_trgm_ops)" unless index_exists?(:reviews, :content, name: "index_reviews_on_content_trgm")
    add_index :reviews, :created_at unless index_exists?(:reviews, :created_at)

    # items
    execute "CREATE INDEX index_items_on_name_trgm ON items USING gin (name gin_trgm_ops)" unless index_exists?(:items, :name, name: "index_items_on_name_trgm")
    execute "CREATE INDEX index_items_on_description_trgm ON items USING gin (description gin_trgm_ops)" unless index_exists?(:items, :description, name: "index_items_on_description_trgm")
    execute "CREATE INDEX index_items_on_manufacturer_trgm ON items USING gin (manufacturer gin_trgm_ops)" unless index_exists?(:items, :manufacturer, name: "index_items_on_manufacturer_trgm")
    execute "CREATE INDEX index_items_on_asin_trgm ON items USING gin (asin gin_trgm_ops)" unless index_exists?(:items, :asin, name: "index_items_on_asin_trgm")

    # releasable_items
    execute "CREATE INDEX index_releasable_items_on_name_trgm ON releasable_items USING gin (name gin_trgm_ops)" unless index_exists?(:releasable_items, :name, name: "index_releasable_items_on_name_trgm")
  end
end
