class AddColumnToEmployee < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :secondary_email, :string
  end
end
