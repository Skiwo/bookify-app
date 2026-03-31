class CreatePasswordlessSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :passwordless_sessions, id: :uuid do |t|
      t.belongs_to :authenticatable, polymorphic: true, type: :uuid, index: { name: "index_passwordless_on_authenticatable" }
      t.datetime :timeout_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :claimed_at
      t.text :token_digest, null: false
      t.string :identifier, null: false
      t.timestamps
    end

    add_index :passwordless_sessions, :token_digest
    add_index :passwordless_sessions, :identifier
  end
end
