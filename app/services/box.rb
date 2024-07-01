class Box
  def initialize(access_token=nil, refresh_token=nil, company_id=nil, app_details)
    if app_details && app_details[:app_details].present?
      @client_id = app_details[:app_details].client_id
      @client_secret = app_details[:app_details].client_secret
      @redirect_uri = app_details[:app_details].redirect_uri
      @scopes = app_details[:app_details].scopes
    end
    @access_token = access_token;
    @base_url = "https://api.box.com/2.0";
    @company_id = company_id;
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

  def refresh_token
    begin
      company_inetgration = CompanyIntegration.where(company_id: @company_id, integration_id: 8).first
      if company_inetgration.present?
        response = RestClient.post("https://api.box.com/oauth2/token", { refresh_token: company_inetgration&.refresh_token, grant_type: "refresh_token", client_id: @client_id, client_secret: @client_secret })
        data = JSON.parse(response.body);
        company_inetgration[:access_token] = data["access_token"]
        company_inetgration.save!
        @access_token = data["access_token"]
        return @access_token
      end
    rescue => e
      return "Error: #{e.message}"
    end
  end

  def create_box_user(email, name)
    begin
      response = RestClient.post("https://api.box.com/2.0/users", {
        login: email,
        name: name,
        role: "user"
      }.to_json, {
        Authorization: "Bearer #{@access_token}",
        content_type: :json,
        accept: :json
      })
      user_data = JSON.parse(response.body)
      puts "User created successfully: #{user_data['name']} (#{user_data['login']})"
      return user_data['id']
    rescue => e
      if e.message = "401 Unauthorized"
        refresh_token
        if refresh_token.include?("Error")
          return refresh_token
        else
          return create_box_user(email, name)
        end
      else
        return nil
      end
      puts "Error creating user: #{e.response}"
      return "Error creating user: #{e.response}"
    end
  end

  def delete_user(id)
    begin
      response = RestClient.delete("https://api.box.com/2.0/users/#{id}",{
        Authorization: "Bearer #{@access_token}",
        content_type: :json,
        accept: :json
      })
    rescue => e
      if e.message = "401 Unauthorized"
        refresh_token
        return delete_user(id)
      end
      puts "Error creating user: #{e.response}"
      return nil
    end
  end

end