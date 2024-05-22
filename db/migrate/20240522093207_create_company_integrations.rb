class CreateCompanyIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :company_integrations do |t|
      t.integer :company_id, null: false
      t.integer :integration_id, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.string :status, null: false, default: "active"
      t.references :companies, index: true, foreign_key: true
      t.references :integrations, index: true, foreign_key: true
      t.timestamps
    end
  end
end
