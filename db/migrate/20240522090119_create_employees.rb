class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.integer :company_id, null: false
      t.string :image, null: true
      t.string :designation, null: false
      t.string :phone, null: false
      t.datetime :joining_date, null: true
      t.string :employee_id, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.references :companies, index: true, foreign_key: true
      t.timestamps
    end
  end
end
