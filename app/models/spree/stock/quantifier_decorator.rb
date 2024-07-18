module Spree
  module Stock
    module QuantifierDecorator
      def self.prepended(base)
        base.include Spree::QuantifierCanSupply
      end
    end
  end
end

Spree::Stock::Quantifier.prepend(Spree::Stock::QuantifierDecorator)
