class AllowNullBodyOnMessages < ActiveRecord::Migration[8.0]
  def change
    change_column_null :messages, :body, true
  end
end
