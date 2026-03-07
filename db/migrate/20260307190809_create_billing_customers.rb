class CreateBillingCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :billing_customers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :external_customer_id, null: false
      t.boolean :livemode, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :billing_customers, [:provider, :external_customer_id], unique: true
    add_index :billing_customers, [:user_id, :provider], unique: true
  end
end
