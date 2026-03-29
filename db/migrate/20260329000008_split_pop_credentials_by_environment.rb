class SplitPopCredentialsByEnvironment < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pop_environment, :string, default: "sandbox", null: false

    rename_column :users, :pop_api_key, :pop_sandbox_api_key
    rename_column :users, :pop_hmac_secret, :pop_sandbox_hmac_secret
    rename_column :users, :pop_partner_id, :pop_sandbox_partner_id

    add_column :users, :pop_production_api_key, :string
    add_column :users, :pop_production_hmac_secret, :string
    add_column :users, :pop_production_partner_id, :string

    remove_column :users, :pop_base_url, :string
  end
end
