module Spree
  module OrderContentsDecorator
    def self.prepended(base)
      base.class_eval do
        alias_method :orig_grab_line_item_by_variant, :grab_line_item_by_variant
      end
    end

    def grab_line_item_by_variant(variant, raise_error = false, options = {})
      return if variant.product.is_gift_card?

      orig_grab_line_item_by_variant(variant, raise_error, options)
    end
  end
end

# Spree::OrderContents.prepend Spree::OrderContentsDecorator
