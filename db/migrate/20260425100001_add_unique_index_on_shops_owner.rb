class AddUniqueIndexOnShopsOwner < ActiveRecord::Migration[8.0]
  def change
    remove_index :shops, :owner_id, if_exists: true
    add_index :shops, :owner_id, unique: true
  end
end
