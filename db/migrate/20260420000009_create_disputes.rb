class CreateDisputes < ActiveRecord::Migration[8.0]
  def change
    create_table :disputes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: true
      t.references :raised_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.integer :status, null: false, default: 0
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
