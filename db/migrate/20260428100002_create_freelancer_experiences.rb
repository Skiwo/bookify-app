class CreateFreelancerExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :freelancer_experiences, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :title,       null: false
      t.string  :company,     null: false
      t.text    :description
      t.date    :started_on,  null: false
      t.date    :ended_on
      t.integer :position,    null: false, default: 0

      t.timestamps
    end
  end
end
