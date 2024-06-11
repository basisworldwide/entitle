class DropBox
  def initialize(access_token=nil)
    @client_id = ENV["DROPBOX_KEY"];
    @client_secret = ENV["DROPBOX_SECRET"];
    @redirect_uri = ENV["DROPBOX_REDIRECT_URI"];
    @access_token = access_token;
    @base_url = "https://api.dropboxapi.com/2";
  end

  def authenticate(integration_id)
    auth_url = "https://www.dropbox.com/oauth2/authorize?client_id=#{@client_id}&redirect_uri=#{@redirect_uri}&token_access_type=offline&state=#{integration_id}&response_type=code"
    return auth_url;
  end

  def generate_token(code)
    begin
      response = RestClient.post "https://www.dropbox.com/oauth2/token", { code: code, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "authorization_code" }
      data = JSON.parse(response.body);
      return data
    rescue Exception => e
      raise e
    end
  end

  def refresh_token(company_id, integration_id)
    begin
      company_inetgration = CompanyIntegration.where(company_id: company_id, integration_id: integration_id).first
      if company_inetgration.present?
        response = RestClient.post("https://www.dropbox.com/oauth2/token", { refresh_token: company_inetgration&.refresh_token, grant_type: "refresh_token", client_id: @client_id, client_secret: @client_secret })
        data = JSON.parse(response.body);
        company_inetgration[:access_token] = data["access_token"]
        company_inetgration.save!
        @access_token = data["access_token"]
        return true;
      end
      return false;
    rescue Exception => e
      raise e
    end
  end

  def invite_member(email, name, company_id, integration_id,role="member_only")
    begin
      url = @base_url + "/team/members/add";
      body = { 
          force_async: false, 
          new_members: [
            {
              member_email: email,
              member_given_name: name,
              send_welcome_email: true,
              role: role,
            }
          ] 
        }.to_json
      response = RestClient.post(url, body, { "Content-Type" => "application/json",:authorization => "Bearer #{@access_token}"})
      data = JSON.parse(response.body);
      return data
    rescue RestClient::ExceptionWithResponse => e
      error = JSON.parse(e.response)
      if error["error"][".tag"] == "invalid_access_token" || error["error"][".tag"] == "expired_access_token"
        begin
          refresh_token(company_id, integration_id)
          data = invite_member(email, name, company_id, integration_id)
          return data
        rescue Exception => err
          return false
        end
      end
      return false
    rescue Exception => e
      return false
    end
  end

  def remove_access(integration_user_id,company_id, integration_id)
    begin
      url = @base_url + "/team/members/remove";
      body = {
          keep_account: false,
          user: {
            ".tag": "team_member_id",
            team_member_id: integration_user_id
          }
        }.to_json
      response = RestClient.post(url, body, { "Content-Type" => "application/json",:authorization => "Bearer #{@access_token}"})
      data = JSON.parse(response.body);
      return data
    rescue RestClient::ExceptionWithResponse => e
      error = JSON.parse(e.response)
      p error
      if error["error"][".tag"] == "invalid_access_token" || error["error"][".tag"] == "expired_access_token"
        begin
          refresh_token(company_id, integration_id)
          data = remove_access(integration_user_id,company_id, integration_id)
          return data
        rescue Exception => err
          return false
        end
      end
      return false
    rescue Exception => e
      p e
      return false
    end
  end
end