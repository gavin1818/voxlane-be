class CreateAuthSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :auth_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :refresh_token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.string :auth_method, null: false
      t.string :user_agent
      t.string :ip_address
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :auth_sessions, :public_id, unique: true
    add_index :auth_sessions, :refresh_token_digest, unique: true
  end
end
