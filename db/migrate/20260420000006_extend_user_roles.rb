class ExtendUserRoles < ActiveRecord::Migration[8.0]
  # Adds client=2 and shop_owner=3 to the existing booker=0, freelancer=1 enum.
  # No data changes needed — integer column, new values simply become available.
  def change
  end
end
