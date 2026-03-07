class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.string :provider, null: false
      t.string :external_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at

      t.timestamps
    end

    add_index :webhook_events, [:provider, :external_event_id], unique: true
  end
end
