module Spree
	module PaymentMethodDecorator
	  def self.prepended(base)
		base.class_eval do
		  scope :gift_card, -> { where(type: 'Spree::PaymentMethod::GiftCard') }
  
		  def gift_card?
			self.class == Spree::PaymentMethod::GiftCard
		  end
		end
	  end
	end
  end
  
  Spree::PaymentMethod.prepend(Spree::PaymentMethodDecorator)