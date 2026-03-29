class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :name
      t.integer :role, null: false, default: 0
      t.datetime :last_sign_in_at
      t.boolean :welcome_dismissed, null: false, default: false
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
