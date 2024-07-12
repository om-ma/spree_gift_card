Spree::CheckoutController.class_eval do

  before_action :load_gift_card, :add_gift_card_payments, only: [:update], if: :payment_via_gift_card?
  before_action :remove_gift_card_payments, only: [:update]

  private

    def add_gift_card_payments
      params[:order].delete(:payments_attributes)
      params.delete(:payment_source)
      adjustment_amount = [@order.total, @gift_card.amount_remaining].min
      if @gift_card.amount_remaining.to_f > 0.0
        if @order.total > @gift_card.amount_remaining
          @order.adjustments.create!(label: 'GIFT CARD', amount: -adjustment_amount, order: @order, source: @gift_card)
          @order.update_with_updater!
          @gift_card.debit(adjustment_amount)
          redirect_to checkout_state_path(@order.state) and return
        else
          @order.next
          @order.adjustments.create!(label: 'GIFT CARD', amount: -adjustment_amount,order: @order)
          @order.update_with_updater!
          @order.update(state: 'complete', completed_at: Time.current)
          handle_zero_amount_payment
          @order.finalize!
          redirect_to completion_route
        end
        @gift_card.debit(adjustment_amount)
      else
        redirect_to checkout_state_path(@order.state) and return
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
        # redirect_to order_path(@order), notice: 'Order paid with gift card successfully!'

      unless @gift_card

        redirect_to checkout_state_path(@order.state), flash: { error: Spree.t(:gift_code_not_found) } and return
      end
    end

    def gift_card_payment_method
      @gift_card_payment_method ||= Spree::PaymentMethod.gift_card.available.first
    end

    def handle_zero_amount_payment
    if @order.total == 0
      payment_method = Spree::PaymentMethod.find_by(type: 'Spree::PaymentMethod::GiftCard') # or your specific payment method
      create_zero_amount_payment(@order, payment_method)
    end
  end

  def create_zero_amount_payment(order, payment_method)
    payment = order.payments.create!(
      amount: 0.0,
      payment_method: payment_method,
      state: 'completed',
      source: @gift_card
    )

    unless payment.persisted?
      flash[:error] = "Payment creation failed"
      redirect_to checkout_state_path(order.state) and return
    end
  end
end
