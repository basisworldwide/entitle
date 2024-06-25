# require 'boxr'

# class Box
    
#     def initialize(access_token=nil, refresh_token = nil)
#         token_refresh_callback = lambda {|access, refresh, identifier| save_box_token(access, refresh)}
#         @client = Boxr::Client.new(access_token,
#                                   refresh_token: refresh_token,
#                                   client_id: client_id,
#                                   client_secret: client_secret,
#                                   &token_refresh_callback)
#     end

#     def save_box_token 
#     end
  
#     def invite(name, email)
#         @client.create_user(name, email)
#     end

#     def authenticate(integration_id)
#         auth_url = "https://account.box.com/api/oauth2/authorize?response_type=code&client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&scope=#{@scopes}&state=#{integration_id}"
#         auth_url
#     end

#   end

class Box
  def initialize(access_token=nil, refresh_token=nil, company_id=nil)
    @client_id = ENV["BOX_CLIENT_ID"];
    @client_secret = ENV["BOX_CLIENT_SECRET"];
    @redirect_uri = ENV["BOX_REDIRECT_URI"];
    @scopes = ENV["BOX_SCOPES"];
    @access_token = access_token;
    @base_url = "https://api.box.com/2.0";
  end
  def authenticate(integration_id)
    auth_url = "https://account.box.com/api/oauth2/authorize?response_type=code&client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&scope=#{@scopes}&state=#{integration_id}"
    auth_url
  end
  def generate_token_by_code(code)
    response = RestClient.post("https://api.box.com/oauth2/token",{
          grant_type: "authorization_code",
          code: code,
          client_id: @client_id,
          client_secret: @client_secret,
          redirect_uri: @redirect_uri
        })
    data = JSON.parse(response.body)
    return data
  end

  def create_box_user(email, name)
    begin
      response = RestClient.post("https://api.box.com/2.0/users", {
        login: email,
        name: name,
        role: "user"
      }.to_json, {
        Authorization: "Bearer #{access_token}",
        content_type: :json,
        accept: :json
      })
      user_data = JSON.parse(response.body)
      puts "User created successfully: #{user_data['name']} (#{user_data['login']})"
      return user_data
    rescue RestClient::ExceptionWithResponse => e
      puts "Error creating user: #{e.response}"
      return nil
    end
  end


end