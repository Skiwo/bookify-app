class CreateEngagements < ActiveRecord::Migration[7.0]
  def change
    create_table :engagements, id: :uuid do |t|
      t.references :booker, type: :uuid, null: false, foreign_key: { to_table: :users }, index: false
      t.references :freelancer, type: :uuid, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :email, null: false
      t.string :pop_worker_id
      t.string :pop_enrollment_id
      t.integer :status, null: false, default: 0
      t.jsonb :pop_profile_data, default: {}
      t.string :invitation_token
      t.datetime :invited_at
      t.datetime :onboarded_at
      t.timestamps
    end

    add_index :engagements, :invitation_token, unique: true
    add_index :engagements, :pop_worker_id
    add_index :engagements, [:booker_id, :email], unique: true
  end
end
