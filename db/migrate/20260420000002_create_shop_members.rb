class CreateShopMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_members, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shop, type: :uuid, null: false, foreign_key: true
      t.references :enrollment, type: :uuid, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :invited_at
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :shop_members, [:shop_id, :enrollment_id], unique: true
  end
end
