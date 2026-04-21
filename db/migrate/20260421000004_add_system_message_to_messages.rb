class AddSystemMessageToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :system_message, :boolean, null: false, default: false
    change_column_null :messages, :sender_id, true
  end
end
