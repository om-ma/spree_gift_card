# lib/spree_gift/flipper_integration.rb
module SpreeGift
  module FlipperIntegration
    def self.gift_card_enabled?
      Flipper.enabled?(:gift_card)
    end
  end
end
