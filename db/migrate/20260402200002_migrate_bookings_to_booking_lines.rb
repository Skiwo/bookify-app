class MigrateBookingsToBookingLines < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      INSERT INTO booking_lines (id, booking_id, description, occupation_code, booking_type,
        rate_ore, hours, work_date, start_time, end_time, total_hours,
        work_start_date, work_end_date, line_external_id, position, created_at, updated_at)
      SELECT gen_random_uuid(), id, description, occupation_code, booking_type,
        rate_ore, hours, work_date, start_time, end_time, total_hours,
        work_start_date, work_end_date, line_external_id, 0, created_at, updated_at
      FROM bookings
    SQL
  end

  def down
    execute <<~SQL
      UPDATE bookings SET
        description = bl.description,
        occupation_code = bl.occupation_code,
        booking_type = bl.booking_type,
        rate_ore = bl.rate_ore,
        hours = bl.hours,
        work_date = bl.work_date,
        start_time = bl.start_time,
        end_time = bl.end_time,
        total_hours = bl.total_hours,
        work_start_date = bl.work_start_date,
        work_end_date = bl.work_end_date,
        line_external_id = bl.line_external_id
      FROM booking_lines bl
      WHERE bl.booking_id = bookings.id AND bl.position = 0
    SQL
  end
end
