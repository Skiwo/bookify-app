class AddBookingTypeFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :booking_type, :integer, default: 0, null: false
    add_column :bookings, :start_time, :time
    add_column :bookings, :end_time, :time
    add_column :bookings, :work_start_date, :date
    add_column :bookings, :work_end_date, :date
    add_column :bookings, :total_hours, :decimal, precision: 8, scale: 2
  end
end
