class AddTripTypeToBookingLines < ActiveRecord::Migration[8.0]
  # Diet (per diem) sub-lines must carry a trip_type so POP can split the
  # per-day amount into tax-free (up to the Skatteetaten satser for that band)
  # and taxable. Only relevant for line_type: :diet.
  def change
    add_column :booking_lines, :trip_type, :string
  end
end
