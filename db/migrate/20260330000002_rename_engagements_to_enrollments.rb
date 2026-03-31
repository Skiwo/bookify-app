class RenameEngagementsToEnrollments < ActiveRecord::Migration[8.0]
  def change
    rename_table :engagements, :enrollments
    rename_column :bookings, :engagement_id, :enrollment_id
  end
end
