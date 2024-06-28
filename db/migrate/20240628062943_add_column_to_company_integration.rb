class AddColumnToCompanyIntegration < ActiveRecord::Migration[7.1]
  def change
    add_column :company_integrations, :aws_access_key_id, :string
    add_column :company_integrations, :aws_secret_access_key, :string
    add_column :company_integrations, :aws_region, :string
  end
end
