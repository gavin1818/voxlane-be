class ReplaceSupabaseIdentityOnUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :supabase_uid, :public_id
    if index_name_exists?(:users, :index_users_on_supabase_uid)
      rename_index :users, :index_users_on_supabase_uid, :index_users_on_public_id
    end

    add_column :users, :password_digest, :string
    add_column :users, :email_verified_at, :datetime
  end
end
