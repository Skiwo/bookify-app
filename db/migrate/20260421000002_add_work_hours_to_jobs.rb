class AddWorkHoursToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :work_date, :date
    add_column :jobs, :work_hours, :decimal, precision: 5, scale: 2
  end
end
