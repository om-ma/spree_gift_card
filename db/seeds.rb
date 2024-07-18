if Spree::Product.gift_cards.count == 0
  puts '\tCreating default gift card...'
  shipping_category = Spree::ShippingCategory.create(name: 'Gift Card')
end

unless Spree::PaymentMethod::GiftCard.all.exists?
  Spree::PaymentMethod::GiftCard.create(
    name: 'Gift Card',
    description: 'Pay by Gift Card',
    active: true,
    display_on: :both
  )
end
