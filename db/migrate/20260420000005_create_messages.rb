class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: true
      t.references :sender, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end

    add_index :messages, [:job_id, :created_at]
  end
end
