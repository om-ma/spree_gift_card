Spree::OrderUpdater.class_eval do
  def grab_line_item_by_variant(variant, raise_error = false, options = {})
    line_item = order.find_line_item_by_variant(variant)
    line_item ||= order.line_items.detect { |li| li.variant_id == variant.id && options_match?(li.options, options) }
    line_item
  end

  def grab_line_item_by_variant_with_gift_card(variant, raise_error = false, options = {})
    return if variant.product.is_gift_card?

    grab_line_item_by_variant_without_gift_card(variant, raise_error, options)
  end

  alias_method :grab_line_item_by_variant_without_gift_card, :grab_line_item_by_variant
  alias_method :grab_line_item_by_variant, :grab_line_item_by_variant_with_gift_card

  private

  def options_match?(existing_options, new_options)
    existing_options.symbolize_keys == new_options.symbolize_keys
  end
end