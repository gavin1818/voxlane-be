class CreateDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_identifier, null: false
      t.string :platform
      t.string :app_version
      t.datetime :last_seen_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :devices, [:user_id, :device_identifier], unique: true
  end
end
