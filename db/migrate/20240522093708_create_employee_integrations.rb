class CreateEmployeeIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_integrations do |t|
      t.integer :employee_id, null: false
      t.integer :integration_id, null: false
      t.string :account_type, null: false
      t.datetime :start_date, null: true
      t.datetime :end_date, null: true
      t.references :employee, index: true, foreign_key: true
      t.references :integration, index: true, foreign_key: true
      t.timestamps
    end
  end
end
