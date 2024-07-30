# app/models/spree/app_configuration_decorator.rb
module Spree
  module AppConfigurationDecorator
    def self.prepended(base)
      base.preference :allow_gift_card_redeem, :boolean, default: false
    end
  end
end


Spree::AppConfiguration.prepend Spree::AppConfigurationDecorator
