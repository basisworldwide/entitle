class CreateActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_logs do |t|
      t.integer :employee_id, null: false
      t.integer :created_by, null: false
      t.string :description, null: false
      t.timestamps
    end
    add_foreign_key :activity_logs, :employees
    add_foreign_key :activity_logs, :users, column: :created_by
  end
end
