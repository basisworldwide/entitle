class AddUserToForeignKeyReference < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :users, :companies
    add_foreign_key :users, :roles
  end
end
