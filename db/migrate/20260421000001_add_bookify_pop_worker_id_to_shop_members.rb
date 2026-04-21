class AddBookifyPopWorkerIdToShopMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_members, :bookify_pop_worker_id, :string
    add_index  :shop_members, :bookify_pop_worker_id
  end
end
