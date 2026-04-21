class AddDesiredFieldsToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :desired_date,  :date
    add_column :jobs, :desired_hours, :decimal, precision: 5, scale: 2
  end
end
