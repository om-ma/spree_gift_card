module Spree
	module ProductDecorator
	  def self.prepended(base)
		base.class_eval do
		  scope :gift_cards, -> { where(is_gift_card: true) }
		  scope :not_gift_cards, -> { where(is_gift_card: false) }
		end
	  end
	end
  end
  
  Spree::Product.prepend(Spree::ProductDecorator)