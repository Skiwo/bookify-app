class AddCompletionTimestampsToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :shop_completed_at, :datetime
    add_column :jobs, :client_completed_at, :datetime
  end
end
