class CreateErrorLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :error_logs do |t|
      t.string :url, null: false
      t.string :payload, null: false
      t.string :description, null: false
      t.integer :created_by, null: true
      t.timestamps
    end
    add_foreign_key :error_logs, :users, column: :created_by
  end
end
