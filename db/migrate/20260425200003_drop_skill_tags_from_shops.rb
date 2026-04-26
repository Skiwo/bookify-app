class DropSkillTagsFromShops < ActiveRecord::Migration[8.0]
  def change
    remove_column :shops, :skill_tags, :string, array: true, default: []
  end
end
