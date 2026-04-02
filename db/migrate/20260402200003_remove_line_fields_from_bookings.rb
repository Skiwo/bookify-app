class RemoveLineFieldsFromBookings < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bookings, :description, true

    remove_column :bookings, :occupation_code, :string
    remove_column :bookings, :booking_type, :integer, default: 0, null: false
    remove_column :bookings, :rate_ore, :integer, null: false
    remove_column :bookings, :hours, :decimal, precision: 8, scale: 2
    remove_column :bookings, :work_date, :date
    remove_column :bookings, :start_time, :time
    remove_column :bookings, :end_time, :time
    remove_column :bookings, :total_hours, :decimal, precision: 8, scale: 2
    remove_column :bookings, :work_start_date, :date
    remove_column :bookings, :work_end_date, :date
    remove_column :bookings, :line_external_id, :string
  end
end
