class AddLineTypeAndReceiptUrlToBookingLines < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_lines, :line_type, :integer, default: 0, null: false
    add_column :booking_lines, :receipt_url, :string
  end
end
