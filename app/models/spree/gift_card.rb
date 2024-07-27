# require 'spree/core/validators/email'

module Spree
  class GiftCard < ActiveRecord::Base
    include CalculatedAdjustments
    include Spree::GiftCard::Users

    UNACTIVATABLE_ORDER_STATES = %w[complete awaiting_return returned].freeze
    AUTHORIZE_ACTION = 'authorize'.freeze
    CAPTURE_ACTION = 'capture'.freeze
    VOID_ACTION = 'void'.freeze
    CREDIT_ACTION = 'credit'.freeze

    belongs_to :variant
    belongs_to :line_item, optional: true

    has_many :transactions, class_name: 'Spree::GiftCardTransaction'

    validates :current_value, :original_value, :code, presence: true
    with_options allow_blank: true do
      validates :code, uniqueness: { case_sensitive: false }
      validates :current_value, numericality: { greater_than_or_equal_to: 0 }
      validates :email, email: true
    end


    validate :amount_remaining_is_positive, if: :current_value

    before_validation :generate_code, on: :create
    before_validation :set_values, on: :create
    after_update_commit :set_gift_delivery_options

    def safely_redeem(user)
      if able_to_redeem?(user)
        redeem(user)
      elsif amount_remaining.to_f > 0.0
        errors.add(:base, Spree.t('errors.gift_card.unauthorized'))
        false
      else
        errors.add(:base, Spree.t('errors.gift_card.already_redeemed'))
        false
      end
    end

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :deliverable, -> { active.where('sent_at IS NULL AND (delivery_on IS NULL OR delivery_on <= ?)', Time.now) }
    
    enum delivery_options: { send_by_email: '0', send_by_pdf: '1', both: '2' }
    enum status: { gift_pending:'0', gift_processing: '1', gift_transfered: '2', gift_canceled: '3' }

    def e_gift_card?
      variant.product.is_e_gift_card?
    end

    def amount_remaining
      current_value - authorized_amount
    end

    def authorize(amount, options = {})
      authorization_code = options[:action_authorization_code]
      if authorization_code
        if transactions.find_by(action: AUTHORIZE_ACTION, authorization_code: authorization_code)
          return true
        else
          errors.add(:base, Spree.t('gift_card_payment_method.unable_to_capture', auth_code: authorization_code))
          return false
        end
      else
        authorization_code = generate_authorization_code
      end

      if valid_authorization?(amount)
        transaction = self.transactions.build(action: AUTHORIZE_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = self.authorized_amount + amount
        self.save!
        authorization_code
      else
        false
      end
    end

    def valid_authorization?(amount)
      if amount_remaining.to_d < amount.to_d
        errors.add(:base, Spree.t('gift_card_payment_method.insufficient_funds'))
        false
      else
        true
      end
    end

    def capture(amount, authorization_code, options = {})
      return false unless authorize(amount, action_authorization_code: authorization_code)

      if amount <= authorized_amount
        transaction = self.transactions.build(action: CAPTURE_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = self.authorized_amount - amount
        self.current_value = self.current_value - amount
        self.save!
        authorization_code
      else
        errors.add(:base, Spree.t('gift_card_payment_method.insufficient_authorized_amount'))
        false
      end
    end

    def void(authorization_code, options = {})
      if auth_transaction = transactions.find_by(action: AUTHORIZE_ACTION, authorization_code: authorization_code)
        amount = auth_transaction.amount
        transaction = self.transactions.build(action: VOID_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.authorized_amount = self.authorized_amount - amount
        self.save!
        true
      else
        errors.add(:base, Spree.t('gift_card_payment_method.unable_to_void', auth_code: authorization_code))
        false
      end
    end

    def credit(amount, authorization_code, options = {})
      capture_transaction = transactions.find_by(action: CAPTURE_ACTION, authorization_code: authorization_code)
      if capture_transaction && amount <= capture_transaction.amount
        transaction = self.transactions.build(action: CREDIT_ACTION, amount: amount, authorization_code: authorization_code)
        transaction.order = Spree::Order.find_by(number: options[:order_number]) if options[:order_number]
        self.current_value = self.current_value + amount
        self.save!
        true
      else
        errors.add(:base, Spree.t('gift_card_payment_method.unable_to_credit', auth_code: authorization_code))
        false
      end
    end

    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end

    def debit(amount, order = nil)
      raise 'Cannot debit gift card by amount greater than current value.' if (amount_remaining - amount.to_f.abs) < 0
      transaction = self.transactions.build
      transaction.amount = amount
      transaction.order  = order if order
      self.current_value = self.current_value - amount.abs
      self.save
    end

    def price
      self.line_item ? self.line_item.price * self.line_item.quantity : self.variant.price
    end

    def order_activatable?(order)
      order &&
      created_at < order.created_at &&
      current_value > 0 &&
      !UNACTIVATABLE_ORDER_STATES.include?(order.state)
    end

    def calculator
      @calculator ||= Spree::Calculator::GiftCardCalculator.new
    end

    def actions
      [:capture, :void]
    end

    def generate_authorization_code
      "#{id}-GC-#{Time.now.utc.strftime('%Y%m%d%H%M%S%6N')}"
    end

    def can_void?(payment)
      payment.pending?
    end

    def can_capture?(payment)
      %w[checkout pending].include?(payment.state)
    end

    private

    def redeem(user)
      begin
        transaction do
          previous_current_value = amount_remaining
          debit(amount_remaining)
          build_store_credit(user, previous_current_value).save!
        end
      rescue Exception => e
        self.errors[:base] = 'There some issue while redeeming the gift card.'
        false
      end
    end

    def build_store_credit(user, previous_current_value)
      user.store_credits.build(
            amount: previous_current_value,
            category: Spree::StoreCreditCategory.gift_card.last,
            memo: "Gift Card - #{ variant.product.name } received from #{ recieved_from }",
            created_by: user,
            action_originator: user,
            currency: Spree::Config[:currency]
        )
    end

    def recieved_from
      line_item.order.email
    end

    def generate_code
      until self.code.present? && self.class.where(code: self.code).count == 0
        self.code = Digest::SHA1.hexdigest([Time.now, rand].join)
      end
    end

    def set_values
      self.current_value ||= self.variant.try(:price)
      self.original_value ||= self.variant.try(:price)
    end

    def amount_remaining_is_positive
      unless amount_remaining >= 0.0
        errors.add(:authorized_amount, Spree.t('errors.gift_card.greater_than_current_value'))
      end
    end

    def able_to_redeem?(user)
      Spree::Config.allow_gift_card_redeem && user && user.email == email && amount_remaining.to_f > 0.0 && line_item.order.completed?
    end

    def set_gift_delivery_options
      order = line_item.order
      gift_card_items = order.line_items.gift_card_items
      return if gift_card_items.count == 1
      selected_gift_option = gift_card_items.first.gift_card

      gift_card_items.each do |line_item|
        gift_card = line_item.gift_card
        next unless gift_card.present?
        gift_card.update_columns(delivery_options: selected_gift_option.delivery_options)
      end
    end
  end
end
