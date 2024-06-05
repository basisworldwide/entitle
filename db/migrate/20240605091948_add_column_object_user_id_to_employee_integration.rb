class AddColumnObjectUserIdToEmployeeIntegration < ActiveRecord::Migration[7.1]
  def change
    add_column :employee_integrations, :integration_user_id, :string
  end
end
