class MakeEngagementIdNullableOnBookings < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bookings, :engagement_id, true
  end
end
