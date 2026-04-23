class AddResponseFieldsToDisputes < ActiveRecord::Migration[8.0]
  def change
    add_column :disputes, :response, :text
    add_reference :disputes, :responded_by, type: :uuid, foreign_key: { to_table: :users }
    add_column :disputes, :responded_at, :datetime
    add_column :disputes, :resolution, :text
    add_reference :disputes, :resolved_by, type: :uuid, foreign_key: { to_table: :users }
  end
end
