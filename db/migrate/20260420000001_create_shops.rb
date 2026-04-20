class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :owner, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.integer :commission_percent, null: false, default: 5
      t.string :city
      t.string :skill_tags, array: true, default: []

      t.timestamps
    end

    add_index :shops, :slug, unique: true
    add_index :shops, :status
    add_index :shops, :visibility
  end
end
