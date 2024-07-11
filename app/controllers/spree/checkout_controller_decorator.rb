Spree::CheckoutController.class_eval do

  before_action :load_gift_card, :add_gift_card_payments, only: [:update], if: :payment_via_gift_card?
  before_action :remove_gift_card_payments, only: [:update]

  private

    def add_gift_card_payments
      debugger
      # @order.add_gift_card_payments(@gift_card)

      # Remove other payment method parameters
      params[:order].delete(:payments_attributes)
      params.delete(:payment_source)

      # Calculate the remaining amount after applying gift card payments
      valid_payments_sum = @order.payments.valid.sum(:amount)
      remaining_amount = @order.total - valid_payments_sum

      if remaining_amount > 0
        # Apply gift card adjustment for the remaining amount
        if @gift_card.amount_remaining >= remaining_amount
          adjustment_amount = remaining_amount
        else
          adjustment_amount = @gift_card.amount_remaining
        end

        if adjustment_amount > 0
          # debugger
          @order.adjustments.create!(label: 'GIFT CARD', amount: -adjustment_amount,order: @order,adjustable: @order, source: @gift_card)

         debugger
          @gift_card.debit(adjustment_amount, @order)
        end



        # Redirect to the payment page if additional payment is still needed
        if @order.total > @order.payments.valid.sum(:amount)
          redirect_to checkout_state_path(@order.state) and return
        end
      end
    end

    def remove_gift_card_payments
      if params.key?(:remove_gift_card) && @order.using_gift_card? && params[:commit] == "Remove Gift Card"
        @order.remove_gift_card_payments
        redirect_to checkout_state_path(@order.state) and return
      end
    end

    def payment_via_gift_card?
      params[:state] == "payment" && params[:order].fetch(:payments_attributes, {}).present? && params[:order][:payments_attributes].select { |payments_attribute| gift_card_payment_method.try(:id).to_s == payments_attribute[:payment_method_id] }.present? && @order.payment?
    end

    def load_gift_card
      @gift_card = Spree::GiftCard.find_by(code: params[:payment_source][gift_card_payment_method.try(:id).to_s][:code])
        # @order.update(payment_state: 'paid',state: "complete", completed_at: Time.now)
        # redirect_to order_path(@order), notice: 'Order paid with gift card successfully!'

      unless @gift_card

        redirect_to checkout_state_path(@order.state), flash: { error: Spree.t(:gift_code_not_found) } and return
      end
    end

    def gift_card_payment_method
      @gift_card_payment_method ||= Spree::PaymentMethod.gift_card.available.first
    end
end
