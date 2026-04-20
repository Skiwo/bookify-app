class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shop, type: :uuid, null: false, foreign_key: true
      t.references :client, type: :uuid, null: false, foreign_key: true
      t.references :assigned_member, type: :uuid, null: true, foreign_key: { to_table: :shop_members }
      t.references :booking, type: :uuid, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :work_amount_ore
      t.integer :commission_amount_ore
      t.datetime :quote_expires_at
      t.datetime :completion_marked_at
      t.datetime :confirmation_deadline_at

      t.timestamps
    end

    add_index :jobs, :status
  end
end
