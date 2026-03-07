class CreateEntitlements < ActiveRecord::Migration[7.2]
  def change
    create_table :entitlements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.string :status, null: false
      t.string :source, null: false
      t.datetime :active_from
      t.datetime :active_until
      t.datetime :trial_ends_at
      t.datetime :last_synced_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :entitlements, [:user_id, :key], unique: true
  end
end
