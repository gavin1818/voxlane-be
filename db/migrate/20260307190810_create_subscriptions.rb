class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :billing_customer, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :external_subscription_id, null: false
      t.string :external_price_id
      t.string :status, null: false
      t.datetime :current_period_end_at
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :canceled_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :subscriptions, [:provider, :external_subscription_id], unique: true
    add_index :subscriptions, [:user_id, :provider]
  end
end
