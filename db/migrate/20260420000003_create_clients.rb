class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, null: true, foreign_key: true
      t.string :org_number, null: false
      t.string :org_name, null: false
      t.string :org_address
      t.datetime :verified_at

      t.timestamps
    end

    add_index :clients, :org_number, unique: true
  end
end
