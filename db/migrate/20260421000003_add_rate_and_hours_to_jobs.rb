class AddRateAndHoursToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :rate_per_hour_ore, :integer
    add_column :jobs, :estimated_hours,   :decimal, precision: 5, scale: 2
  end
end
