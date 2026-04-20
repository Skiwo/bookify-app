class CreateShopInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shop, type: :uuid, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :shop_invitations, :token, unique: true
    add_index :shop_invitations, [:shop_id, :email], unique: true
  end
end
