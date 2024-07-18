module Spree
	module LineItemDecorator
	  MAXIMUM_GIFT_CARD_LIMIT = 1
  
	  def self.prepended(base)
	   base.has_one :gift_card, dependent: :destroy
  
	   # base.with_options if: :is_gift_card? do
		#  base.validates :gift_card, presence: true
		#  base.validates :quantity, numericality: { less_than_or_equal_to: Spree::LineItemDecorator::MAXIMUM_GIFT_CARD_LIMIT }, allow_nil: true
	   # end
  
	   # base.delegate :is_gift_card?, to: :product
	  end
	end
  end
  
  Spree::LineItem.prepend(Spree::LineItemDecorator)
  