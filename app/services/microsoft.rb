require 'rest-client'
require 'json'

class Microsoft

  def initialize(access_token=nil)
    @client_id = ENV["MICROSOFT_CLIENT_ID"];
    @tenant_id = ENV["MICROSOFT_TENANT_ID"];
    @client_secret = ENV["MICROSOFT_CLIENT_SECRET"];
    @redirect_uri = ENV["MICROSOFT_REDIRECT_URI"];
    @access_token = access_token;
    @base_url = "https://graph.microsoft.com/v1.0";
    @invite_redirect_url = "https://www.microsoft.com/en-in/";
    @auth_url = "https://login.microsoftonline.com"
  end

  def authenticate(integration_id)
    url = "#{@auth_url}/common/adminconsent?client_id=#{@client_id}&state=#{integration_id}&redirect_uri=#{@redirect_uri}";
    return url
  end

  def generate_token(tenant_id)
    begin
    url = "#{@auth_url}/#{tenant_id}/oauth2/v2.0/token";
    response = RestClient.post url, { client_id: @client_id, client_secret: @client_secret, scope: "https://graph.microsoft.com/.default", grant_type: "client_credentials" }
    data = JSON.parse(response.body);
    return data["access_token"]
    rescue Exception => e
      raise e
    end
  end

  def refresh_token(company_id, integration_id)
    access_token = generate_token(@tenant_id);
    company_inetgration = CompanyIntegration.where(company_id: company_id, integration_id: integration)
    if company_inetgration.present?
      company_inetgration[:access_token] = access_token
      company_inetgration[:refresh_token] = access_token
      company_inetgration.save!
      return true;
    end
    return false;
  end

  def invite_user(email, name)
    begin
      url = @base_url + "/invitations";
      response = RestClient.post(url, { invitedUserEmailAddress: email, inviteRedirectUrl: @invite_redirect_url }.to_json, { :authorization => "Bearer #{@access_token}"})
      data = JSON.parse(response.body);
      return data
    rescue RestClient::ExceptionWithResponse => e
      raise e
    rescue Exception => e
      raise e
    end
  end

  def remove_access(userObjectId)
    url = @base_url + "/users/#{userObjectId}";
    response = RestClient.delete(url, { :authorization => "Bearer #{@access_token}"})
    data = JSON.parse(response.body);
  end

end