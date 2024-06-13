require 'slack-ruby-client'

class SlackService
    def initialize(token, channel_name = "social")
      @token = token
      raise 'Missing Slack API Token!' unless @token
      @client = Slack::Web::Client.new(token: @token)
      @team_id = get_team_id
      @channel_id = get_channel_id(channel_name)
    end
  
    def invite_member(email)
      @client.admin_users_invite({channel_ids: @channel_id, team_id: @team_id, email: email})
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error("Slack API error: #{e.message}")
    end

    def get_team_id
        response = @client.auth_test
        response['team_id']
    rescue Slack::Web::Api::Errors::SlackError => e
        Rails.logger.error("Slack API error: #{e.message}")
        nil
    end

    def get_channel_id(channel_name)
        response = @client.conversations_list
        channel = response['channels'].find { |ch| ch['name'] == channel_name }
        channel ? channel['id'] : nil
    rescue Slack::Web::Api::Errors::SlackError => e
        Rails.logger.error("Slack API error: #{e.message}")
        nil
    end
  end