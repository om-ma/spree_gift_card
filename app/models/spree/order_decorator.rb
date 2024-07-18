module Spree
	module OrderDecorator
	  def self.prepended(base)
		base.class_eval do
		  include Spree::Order::GiftCard
		end
	  end
	end
  end
  
  Spree::Order.prepend(Spree::OrderDecorator)
  