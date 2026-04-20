class CreateJobReads < ActiveRecord::Migration[8.0]
  def change
    create_table :job_reads, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job,  null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime   :last_read_at, null: false

      t.timestamps
    end

    add_index :job_reads, [:job_id, :user_id], unique: true
  end
end
