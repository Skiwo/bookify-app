class AddSoloFreelancerEnrollment < ActiveRecord::Migration[8.0]
  def change
    # Global POP worker_id for the freelancer — one enrollment per person under Bookify account.
    # Reused across solo shop + any roster memberships they join later.
    add_column :users, :bookify_pop_worker_id, :string

    # Marks a shop as auto-created for a solo freelancer (no commission, owner = member)
    add_column :shops, :solo, :boolean, null: false, default: false
  end
end
