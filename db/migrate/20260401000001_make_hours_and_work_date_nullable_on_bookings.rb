class MakeHoursAndWorkDateNullableOnBookings < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bookings, :hours, true
  end
end
