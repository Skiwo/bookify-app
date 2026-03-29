class CreatePayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :payouts, id: :uuid do |t|
      t.references :booking, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.string :pop_payout_id
      t.string :pop_status
      t.integer :amount_ore
      t.string :pop_invoice_number
      t.jsonb :pop_response, default: {}
      t.datetime :synced_at
      t.timestamps
    end

    add_index :payouts, :pop_payout_id, unique: true
  end
end
