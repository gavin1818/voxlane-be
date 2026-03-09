class CreateAuthIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :auth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :email
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :auth_identities, [ :provider, :provider_uid ], unique: true
    add_index :auth_identities, [ :user_id, :provider ], unique: true
  end
end
