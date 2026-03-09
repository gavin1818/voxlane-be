class CreateDesktopLoginRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :desktop_login_requests do |t|
      t.references :user, foreign_key: true
      t.string :public_id, null: false
      t.string :polling_token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :approved_at
      t.datetime :completed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :desktop_login_requests, :public_id, unique: true
    add_index :desktop_login_requests, :polling_token_digest, unique: true
  end
end
