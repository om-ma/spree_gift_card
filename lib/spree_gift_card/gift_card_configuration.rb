module SpreeGiftCard
  class GiftCardConfiguration < Spree::Preferences::Configuration  
    preference :allow_gift_card_redeem, :boolean, default: true
  end
end
