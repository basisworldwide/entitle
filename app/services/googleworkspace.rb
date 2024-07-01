require 'rest-client'
require 'json'

class Googleworkspace
  def initialize(access_token=nil, refresh_token=nil, company_id=nil, app_details)
    if app_details && app_details[:app_details].present?
      @client_id = app_details[:app_details].client_id
      @client_secret = app_details[:app_details].client_secret
      @redirect_uri = app_details[:app_details].redirect_uri
      @scopes = app_details[:app_details].scopes
    end
    @access_token = access_token;
    @base_url = "https://admin.googleapis.com/admin/directory/v1"
    @refresh_token = refresh_token
    @company_id = company_id
  end

  def get_google_auth_url(integrtaion_id)
    @google_auth_url = "https://accounts.google.com/o/oauth2/v2/auth?scope="+@scopes+"&access_type=offline&include_granted_scopes=true&response_type=code&state="+integrtaion_id+"&redirect_uri="+@redirect_uri+"&client_id="+@client_id+"&service=lso&o2v=2&ddm=0"
  end

  def generate_token_by_code(code)
    response = RestClient.post 'https://oauth2.googleapis.com/token', { code: code, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "authorization_code" }
    data = JSON.parse(response.body);
    return data
  end

  def invite_user_to_workspace(email, name, secondary_email)
    require 'google/apis/admin_directory_v1'
    
    begin
      Rails.logger.info "Starting the user invitation process"
      
      #Initialize the Directory Service
      service = Google::Apis::AdminDirectoryV1::DirectoryService.new
      service.client_options.application_name = 'Entitle'
      service.authorization = @access_token  # Use instance variable @access_token
    
      # Create a new user object without specifying password
      password = "Test@123!"
      user_object = Google::Apis::AdminDirectoryV1::User.new(
        primary_email: email,
        name: Google::Apis::AdminDirectoryV1::UserName.new(
          given_name: name,
          family_name: "User"
        ),
        password: password,
        org_unit_path: "/"  # Specify the organizational unit path if needed
      )
    
      # Insert the new user
      result = service.insert_user(user_object)
      customer_id = result.customer_id
      begin
        UserMailer.workspace_invitation(name, secondary_email, email, password).deliver_now
        p "success in sending email"
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
          p Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        p "error in sending email"
      rescue => e
        p e
      end
      Rails.logger.info "User #{email} invited successfully with customer_id: #{customer_id}."

      return customer_id
    rescue => e
      if e.message == "Unauthorized"
        new_access_token_from_refresh_token()
        invite_user_to_workspace(email, name)
      else
        Rails.logger.error "Error inviting user #{email}: #{e.message}"
        return e
      end
    end
  end

  def new_access_token_from_refresh_token
    begin
      response = RestClient.post 'https://oauth2.googleapis.com/token', {
        refresh_token: @refresh_token,
        client_id: @client_id,
        client_secret: @client_secret,
        redirect_uri: @redirect_uri,
        grant_type: 'refresh_token'
      }
      data = JSON.parse(response)
      update_access_token_in_database(@refresh_token, data['access_token'])
      @access_token = data['access_token']
      return @access_token
    rescue => e
      # if refresh token also expired
      if e.message == 'invalid_grant'
        # Delete tokens from the database
        remove_company_integration()
        # Redirect to authentication URL
        auth_url = get_google_auth_url(4)
        redirect_to(auth_url)
      else
        return e
      end
    end
  end
  
  def update_access_token_in_database(refresh_token, new_access_token)
    company_integration = CompanyIntegration.where(refresh_token: refresh_token, integration_id: 4, company_id: @company_id).first
    company_integration.update(access_token: new_access_token)
  end

  def revoke_token
    begin
      # Properly format the token parameter for the request
      response = RestClient.post 'https://oauth2.googleapis.com/revoke',
                                 { token: @access_token },
                                 content_type: 'application/x-www-form-urlencoded'
      # Assuming successful revocation returns an empty response with HTTP 200 status
      if response.code == 200
        Rails.logger.info "Token revoked successfully."
        remove_company_integration()
      else
        Rails.logger.error "Failed to revoke token. Response code: #{response.code}, Body: #{response.body}"
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "Error revoking token: #{e.response}"
    rescue => e
      if e.message == "Unauthorized" || e.message == "401 Unauthorized"
        new_access_token_from_refresh_token()
        revoke_token
      else
        Rails.logger.error "Error revoking token: #{e.message}"
        remove_company_integration()
      end
    end
  end

  def remove_company_integration
    company_integration = CompanyIntegration.where(integration_id: 4, company_id: @company_id)
    # Destroy all records that match the query
    if company_integration.any?
      company_integration.each do |integration|
        integration.destroy
      end
      Rails.logger.info "Company integrations destroyed successfully."
    else
      Rails.logger.warn "No company integrations found to destroy."
    end
  end

  def delete_workspace_user(primary_email)
    begin
      response = RestClient.delete "https://admin.googleapis.com/admin/directory/v1/users/#{primary_email}",
                                   { Authorization: "Bearer #{@access_token}" }
     
      if response.code == 204
        Rails.logger.info "User #{primary_email} deleted successfully."
        return true
      else
        Rails.logger.error "Failed to delete user #{primary_email}. Response code: #{response.code}, Body: #{response.body}"
        return false
      end
    rescue => e
      if e.message == "401 Unauthorized"
        new_access_token_from_refresh_token()
        delete_workspace_user(primary_email)
      else
        Rails.logger.error "Error inviting user #{primary_email}: #{e.message}"
        return e
      end
    end
  end

  def invite_user_to_cloud(email, role = 'roles/viewer')
    require 'google/apis/cloudresourcemanager_v1'
    begin
      Rails.logger.info "Starting the Google Cloud user invitation process"
      
      service = Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService.new
      service.client_options.application_name = 'Entitle'
      service.authorization = @access_token
    
      binding = Google::Apis::CloudresourcemanagerV1::Binding.new(
        members: ["user:#{email}"],
        role: role
      )
    
      policy = service.get_project_iam_policy("invite-users-426708")
      policy.bindings << binding
    
      request = Google::Apis::CloudresourcemanagerV1::SetIamPolicyRequest.new(policy: policy)
      data = service.set_project_iam_policy("invite-users-426708", request)
      return data
      Rails.logger.info "User #{email} invited to Google Cloud project #{"invite-users-426708"} successfully."
    rescue => e
      if e.message.include?("401 Unauthorized") || e.message.include?("Unauthorized")
        new_access_token_from_refresh_token()
        invite_user_to_cloud(email, "invite-users-426708", role)
      else
        Rails.logger.error "Error inviting user #{email} to Google Cloud: #{e.message}"
        return e
      end
    end
  end
  def delete_cloud_user(email, role = 'roles/viewer')
    begin
      service = Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService.new
      service.authorization = @access_token

      policy = service.get_project_iam_policy("invite-users-426708")

      # Remove all bindings for the specified member (user)
      policy.bindings.reject! { |binding| binding.members.include?("user:#{email}") && binding.role == role }

      request = Google::Apis::CloudresourcemanagerV1::SetIamPolicyRequest.new(policy: policy)
      service.set_project_iam_policy("invite-users-426708", request)

      Rails.logger.info "User #{email} removed from role #{role} in project #{"invite-users-426708"} successfully."
    rescue => e
      if e.message == "401 Unauthorized"
        new_access_token_from_refresh_token()
        delete_workspace_user(primary_email)
      else
        Rails.logger.error "Error inviting user #{primary_email}: #{e.message}"
        return e
      end
    end
  end

end
