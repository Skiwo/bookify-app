class CreateBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings, id: :uuid do |t|
      t.references :engagement, type: :uuid, null: false, foreign_key: true
      t.string :description, null: false
      t.string :occupation_code
      t.integer :status, null: false, default: 0
      t.integer :rate_ore, null: false
      t.decimal :hours, precision: 8, scale: 2, null: false
      t.date :work_date
      t.string :order_reference
      t.timestamps
    end

    add_index :bookings, :status
  end
end
