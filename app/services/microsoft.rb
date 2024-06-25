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
    company_inetgration = CompanyIntegration.where(company_id: company_id, integration_id: integration_id).first
    if company_inetgration.present?
      company_inetgration[:access_token] = access_token
      company_inetgration[:refresh_token] = access_token
      company_inetgration.save!
      @access_token = access_token
      return true;
    end
    return false;
  end

  def invite_user(email, name,company_id, integration_id)
    begin
      url = "#{@base_url}/invitations"
      response = RestClient.post(url, {
        invitedUserEmailAddress: email,
        inviteRedirectUrl: @invite_redirect_url,
        sendInvitationMessage: true
      }.to_json, {
        :authorization => "Bearer #{@access_token}",
        :content_type => :json,
        :accept => :json
      })
      data = JSON.parse(response.body)
      return data
    rescue RestClient::BadRequest => e
      p e.response.body
      return false
    rescue => e
      p e
      return false
    end
  end

  def remove_access(userObjectId,company_id,integration_id)
    begin
      url = @base_url + "/users/#{userObjectId}";
      response = RestClient.delete(url, { :authorization => "Bearer #{@access_token}"})
      data = JSON.parse(response.body);
    rescue RestClient::ExceptionWithResponse => e
      error = JSON.parse(e.response)
      if error["error"]["code"] == "Unauthorized" || error["error"]["code"] == "InvalidAuthenticationToken"
        begin
          refresh_token(company_id, integration_id)
          data = remove_access(userObjectId,company_id,integration_id)
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

  def invite_user_to_teams(email, name,company_id, integration_id)
    team_id = "a23c7e91-1dc5-4295-ae27-1c88522e1057"
    # invite_user = invite_user(email, name,company_id, integration_id)
    # invite_user["id"]
    begin
      url = "#{@base_url}/teams/#{team_id}/members"
      response = RestClient.post(url, {
            '@odata.type': 'microsoft.graph.aadUserConversationMember',
            roles: ['member'],
            'user@odata.bind': "https://graph.microsoft.com/v1.0/users('98fc408a-4f20-4246-a4da-636e5a8edcdd')"
          }.to_json, { :authorization => "Bearer #{@access_token}" })
      p "================================================================"
      data = JSON.parse(response.body)
      p data
      return data
    rescue => e
      p "error+++++>#{e.message}"
      p "Response code: #{e.response.code}"
      p "Response body: #{e.response.body}"
    end
  end

  def delete_team_member(team_id, membership_id)
    begin
      url = "#{@base_url}/teams/#{team_id}/members/#{membership_id}"
      response = RestClient.post(url, {
        '@odata.type': 'microsoft.graph.aadUserConversationMember',
        roles: ['member'],
        'user@odata.bind': "https://graph.microsoft.com/v1.0/users/#{email}"
      }.to_json, { :authorization => "Bearer #{@access_token}" })
      JSON.parse(response.body)
    rescue => e
      p e
    end
  end

  # def invite_user_to_sharepoint(email, site_url)
  #   begin
  #     url = "https://geekbasis.sharepoint.com/sites/YourSiteName/"
  #     response = RestClient.post(url, {
  #       invitedUserEmailAddress: email,
  #       inviteRedirectUrl: @invite_redirect_url,  # Ensure invite_redirect_url is defined correctly
  #       sendInvitationMessage: true
  #     }.to_json, { :authorization => "Bearer #{@access_token}", :content_type => :json })
  #     JSON.parse(response.body)
  #   rescue => e
  #     puts "Error inviting user to SharePoint: #{e.message}"
  #   end
  # end

  def invite_user_to_sharepoint(email)
    p @access_token
    begin
      url = "https://geekbasis.sharepoint.com/sites/Entitle/_api/SP.Sharing.InviteByEmail"
      response = RestClient.post(url, {
        email: email,
        includeAnonymousLinkInEmail: false,
        role: "View"  # Specify the role here, e.g., "View" or "Edit"
      }.to_json, { :authorization => "Bearer #{@access_token}", :content_type => :json })
      p "++++++++++++++++++++++++++++++++++++++++++++++++"
      p JSON.parse(response.body)
    rescue => e
      puts "Error inviting user to SharePoint: #{e.message}"
    end
  end

  def invite_user_to_azure(email, invite_redirect_url)
    begin
      url = "#{@base_url}/invitations"
      response = RestClient.post(url, {
        invitedUserEmailAddress: email,
        inviteRedirectUrl: invite_redirect_url,
        sendInvitationMessage: true
      }.to_json, { :authorization => "Bearer #{@access_token}", :content_type => :json })
      JSON.parse(response.body)
    rescue  => e
      p e
    end
  end

  def one_drive_invitation
    #POST https://graph.microsoft.com/v1.0/drives/<driveId>/items/<folderId>/invite
    response = RestClient.post( "https://graph.microsoft.com/v1.0/me/drive/{driveId}/invite",
    {
      "recipients": [
        {
          "email": "user@example.com"
        }
      ],
      "requireSignIn": true,
      "sendInvitation": true,
      "roles": ["write", "read"]
    })
    
  end 

end