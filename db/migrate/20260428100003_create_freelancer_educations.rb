class CreateFreelancerEducations < ActiveRecord::Migration[8.0]
  def change
    create_table :freelancer_educations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :institution,     null: false
      t.string  :degree
      t.string  :field_of_study
      t.integer :graduation_year
      t.integer :position,        null: false, default: 0

      t.timestamps
    end
  end
end
