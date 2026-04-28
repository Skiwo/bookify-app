class AddFreelancerProfileToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :headline,          :string
    add_column :users, :bio,               :text
    add_column :users, :location,          :string
    add_column :users, :hourly_rate_ore,   :integer
    add_column :users, :experience_level,  :string
    add_column :users, :profile_public,    :boolean, null: false, default: false
    add_column :users, :profile_slug,      :string
    add_column :users, :profile_skill_tags, :string, array: true, default: []

    add_index :users, :profile_slug, unique: true, where: "profile_slug IS NOT NULL"
  end
end
