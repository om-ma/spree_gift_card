module Spree
	module LineItemDecorator
	  MAXIMUM_GIFT_CARD_LIMIT = 1

		def self.prepended(base)
	   	base.has_one :gift_card, dependent: :destroy
		 	base.after_destroy :remove_gift_card_payment
	  end

		private

		def remove_gift_card_payment
      return unless gift_card?
			order.payments.gift_cards.checkout.map(&:invalidate!)
    end

    def gift_card?
			product = variant.product
			product.is_gift_card? || product.variants.any? { |item| item.is_specific_gift_card? }
		end

	end
end

Spree::LineItem.prepend(Spree::LineItemDecorator)
