module Spree
  module Admin
    class GiftCardsController < Spree::Admin::ResourceController
      before_action :find_gift_card_variants, except: :destroy

      def create
        @object.assign_attributes(gift_card_params)
        @object.created_by = 1
        if @object.save
          Spree::OrderMailer.gift_card_email(@object.id, nil).deliver_later
          flash[:success] = Spree.t(:successfully_created_gift_card)
          redirect_to admin_gift_cards_path
        else
          render :new
        end
      end

      private
      def collection
        super.order(created_at: :desc).page(params[:page]).per(Spree::Config[:admin_orders_per_page])
      end

      def find_gift_card_variants
        gift_card_product_ids = Product.not_deleted.where(is_gift_card: true).pluck(:id)
        @gift_card_variants = Variant.joins(:prices).where(["amount > 0 AND product_id IN (?)", gift_card_product_ids]).order("amount")
      end

      def gift_card_params
        params.require(:gift_card).permit(:email, :name, :note, :value, :variant_id, :enabled)
      end

    end
  end
end
