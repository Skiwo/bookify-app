class CreateSkillsAndShopSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :slug,     null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :skills, :slug, unique: true
    add_index :skills, :position

    create_table :shop_skills, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shop,  null: false, foreign_key: true, type: :uuid
      t.references :skill, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :shop_skills, [:shop_id, :skill_id], unique: true
  end
end
