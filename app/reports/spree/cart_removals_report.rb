module Spree
  class CartRemovalsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { sku: :string, product_name: :string, removals: :integer, quantity_change: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_removed_from, end_date: :product_removed_to }
    SORTABLE_ATTRIBUTES = [:product_name, :sku, :removals, :quantity_change]

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate
      SpreeAdminInsights::ReportDb[:spree_cart_events___cart_events].
      join(:spree_variants___variants, id: :variant_id).
      join(:spree_products___products, id: :product_id).
      where(cart_events__activity: 'remove').
      where(cart_events__created_at: @start_date..@end_date). #filter by params
      group(:variant_id).
      order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select{[
        products__name.as(product_name),
        Sequel.as(IF(STRCMP(variants__sku, ''), variants__sku, products__name), :sku),
        Sequel.as(count(:products__name), :removals),
        Sequel.as(sum(cart_events__quantity), :quantity_change)
      ]}
    end
  end
end
