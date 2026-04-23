class CreateQuoteLines < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_lines, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, null: false, foreign_key: true, type: :uuid
      t.string     :description, null: false
      t.integer    :rate_ore, null: false
      t.decimal    :hours, precision: 5, scale: 2, null: false, default: 1
      t.integer    :amount_ore, null: false
      t.integer    :position, null: false, default: 0

      t.timestamps
    end
  end
end
