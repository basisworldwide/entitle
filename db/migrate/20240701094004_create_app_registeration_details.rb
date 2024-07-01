class CreateAppRegisterationDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :app_registeration_details do |t|
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :redirect_uri, null: false
      t.string :group_id
      t.string :tenant_id
      t.string :scopes
      t.string :company_id, null: false
      t.references :integration, index: true, foreign_key: true
      t.timestamps
    end
  end
end
