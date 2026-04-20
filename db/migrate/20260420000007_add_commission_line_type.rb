class AddCommissionLineType < ActiveRecord::Migration[8.0]
  # Adds commission=4 to BookingLine line_type enum (work=0, benefit=1, expense=2, diet=3).
  # No data changes needed — integer column, new value simply becomes available.
  def change
  end
end
