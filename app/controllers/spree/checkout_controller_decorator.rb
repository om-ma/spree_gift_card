module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :load_gift_card, only: [:update], if: :payment_via_gift_card?
      base.before_action :add_gift_card_payments, only: [:update], if: :payment_via_gift_card?
    end
    private

    def add_gift_card_payments
      if Flipper.enabled?(:gift_card)
        if spree_current_user.present? && !spree_current_user.gift_cards.include?(@gift_card)
          spree_current_user.gift_cards << @gift_card
        end
        @order.add_gift_card_payments(@gift_card)

        # Remove other payment method parameters.
        params[:order].delete(:payments_attributes)
        params.delete(:payment_source)

        # Return to the Payments page if additional payment is needed.
        if @order.payments.valid.sum(:amount) < @order.total
          redirect_to checkout_state_path(@order.state)
          flash[:success] = Spree.t('gift_card_added_partial')
          return
        else
          flash[:success] = Spree.t('gift_card_added')
        end
      end
    end

    def payment_via_gift_card?
      if Flipper.enabled?(:gift_card)
        params[:state] == 'payment' &&
          params[:order].fetch(:payments_attributes, {}).present? &&
          params[:order][:payments_attributes].select { |payments_attribute| gift_card_payment_method.try(:id).to_s == payments_attribute[:payment_method_id] }.present?
      end
    end

    def load_gift_card
      if Flipper.enabled?(:gift_card)
        @gift_card = Spree::GiftCard.find_by(code: params[:payment_source][gift_card_payment_method.try(:id).to_s][:code])
        if @gift_card.nil?
          @gift_card = import_integrated_gift_card
        else
          sync_integrated_gift_card(@gift_card)
        end
        if @gift_card.present?
          unless eligible_for_gift?
            redirect_to checkout_state_path(@order.state), flash: { error: Spree.t('specific_gift_code') } and return
          end
        else
          redirect_to checkout_state_path(@order.state), flash: { error: Spree.t('gift_code_not_found') } and return
        end
      end
    end

    def product_having_variant(gift_card, order)
      variant = gift_card.variant
      product = variant.product
      order_variant_ids = order.products.flat_map { |product| product.variants.ids }
      variant_ids = product.variants.ids
      (order_variant_ids & variant_ids).any?
    end

    def eligible_for_gift?
      if @gift_card.check_specific_gift_card? || @order.specific_gift_card_only?
        if product_having_variant(@gift_card, @order)
          return true
        end
        return false
      end
      true
    end

    def gift_card_payment_method
      @gift_card_payment_method ||= Spree::PaymentMethod.gift_card.available.first
    end

    def import_integrated_gift_card; end

    def sync_integrated_gift_card(_gift_card)
      true
    end
  end
end
::Spree::CheckoutController.prepend(Spree::CheckoutControllerDecorator)