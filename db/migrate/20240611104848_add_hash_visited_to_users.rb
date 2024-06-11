class AddHashVisitedToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hash_visited, :boolean
  end
end
