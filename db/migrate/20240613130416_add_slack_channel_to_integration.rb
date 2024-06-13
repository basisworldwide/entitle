class AddSlackChannelToIntegration < ActiveRecord::Migration[7.1]
  def change
    add_column :company_integrations, :slack_channels, :string
  end
end
