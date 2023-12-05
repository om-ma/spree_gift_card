module Spree
  # GiftCard class enhancement
  class GiftCard < ActiveRecord::Base
    has_many :user_gift_cards
    has_many :users, through: :user_gift_cards

    # GiftCard may have many owners
    module Users
      extend ActiveSupport::Concern

      included do
        # Define methods or associations here
        def belongs_to?(user)
          owners.include?(user)
        end
      end
    end

    include Users # Including the module within GiftCard class
  end
end