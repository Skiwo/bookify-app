class AddPopCredentialsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pop_api_key, :string
    add_column :users, :pop_hmac_secret, :string
    add_column :users, :pop_partner_id, :string
    add_column :users, :pop_base_url, :string
  end
end
