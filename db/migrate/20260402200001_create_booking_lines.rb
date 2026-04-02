class CreateBookingLines < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_lines, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :booking_id, null: false
      t.string :description, null: false
      t.string :occupation_code
      t.integer :booking_type, default: 0, null: false
      t.integer :rate_ore, null: false
      t.decimal :hours, precision: 8, scale: 2
      t.date :work_date
      t.time :start_time
      t.time :end_time
      t.decimal :total_hours, precision: 8, scale: 2
      t.date :work_start_date
      t.date :work_end_date
      t.string :line_external_id
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :booking_lines, [:booking_id, :position]
    add_foreign_key :booking_lines, :bookings
  end
end
