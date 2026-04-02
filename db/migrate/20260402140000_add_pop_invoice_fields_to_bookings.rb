class AddPopInvoiceFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    change_table :bookings, bulk: true do |t|
      t.date :invoiced_on
      t.date :due_on
      t.string :buyer_reference
      t.text :external_note
      t.string :line_external_id
    end
  end
end
