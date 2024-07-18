class CreateSpreeGiftCards < ActiveRecord::Migration[4.2]
  def change
    create_table :spree_gift_cards do |t|
      t.integer :variant_id, null: false
      t.integer :line_item_id, null: false
      t.string :email
      t.string :name, null: false
      t.string :sender_email 
      t.string :sender_name, null: false
      t.text :message, null: false
      t.string :code, null: false
      t.integer :status, null: false, default: 0
      t.boolean :is_information_verified, null: false
      t.boolean :should_receive_copies, null: false, default: false
      t.datetime :sent_at
      t.datetime :delivery_date
      t.datetime :expiry_date
      t.decimal :current_value, precision: 8, scale: 2, null: false
      t.decimal :original_value, precision: 8, scale: 2, null: false
      t.timestamps
    end
  end
end
