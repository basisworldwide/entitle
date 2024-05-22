class CreateIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :integrations do |t|
      t.string :name, null: false, index: { unique: true}
      t.string :description, null: false
      t.string :logo, null: true
      t.timestamps
    end
  end
end
