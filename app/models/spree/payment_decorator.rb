module Spree
  module PaymentDecorator
    def self.prepended(base)
      base.class_eval do
        scope :gift_cards, -> { where(source_type: Spree::GiftCard.to_s) }

        delegate :gift_card?, to: :payment_method, allow_nil: true

        #state_machine.after_transition to: :completed, do: :process_gift_card

        # def process_gift_card
        #   order.line_items.each do |li|
        #     if li.gift_card
        #       li.gift_card.update_column(:enabled, true)
        #       Spree::OrderMailer.gift_card_email(li.gift_card.id, order).deliver_later
        #     end
        #   end
        # end

        def store_credit_or_gift_card?
          store_credit? || gift_card?
        end

        private

        def invalidate_old_payments
          return if store_credit_or_gift_card?
          order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
            # payment.invalidate! unless payment.store_credit_or_gift_card?
          end
        end
      end
    end
  end
end

Spree::PaymentMethod.prepend(Spree::PaymentMethodDecorator)
