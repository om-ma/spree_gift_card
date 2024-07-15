require_relative 'gift_card_configuration'

module SpreeGiftCard
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_gift_card'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/models/spree/calculator/*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    initializer 'spree.backend.environment', before: :load_config_initializers do |app|
      SpreeGiftCard::Config = SpreeGiftCard::GiftCardConfiguration.new
    end

    config.after_initialize do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::GiftCard
    end

    config.after_initialize do |app|
      Spree::PermittedAttributes.source_attributes << :code
    end

    config.to_prepare &method(:activate).to_proc
  end
end
