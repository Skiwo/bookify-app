class AddBookifyFeeEnabledToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :bookify_fee_enabled, :boolean, null: false, default: false
  end
end
