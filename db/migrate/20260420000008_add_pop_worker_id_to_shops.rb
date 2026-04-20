class AddPopWorkerIdToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :pop_worker_id, :string
  end
end
