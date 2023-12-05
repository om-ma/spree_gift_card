module Spree
  module LineItemDecorator 

    MAXIMUM_GIFT_CARD_LIMIT ||= 1

    def self.prepended(base)   
      base.has_one :gift_card, dependent: :destroy
      base.validates :gift_card, presence: false, if: :is_gift_card?
      base.validates :quantity,  numericality: { less_than_or_equal_to: MAXIMUM_GIFT_CARD_LIMIT }, allow_nil: true, if: :is_gift_card?
      base.delegate :is_gift_card?, to: :product
      base.delegate :is_e_gift_card?, to: :product
    end
  end
end
::Spree::LineItem.prepend(Spree::LineItemDecorator)
