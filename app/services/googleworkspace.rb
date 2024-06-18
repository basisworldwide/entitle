require 'rest-client'
require 'json'

class Googleworkspace
  def initialize(access_token=nil, refresh_token=nil, company_id=nil,)
    @client_id = ENV["GOOGLE_CLIENT_ID"];
    @client_secret = ENV["GOOGLE_CLIENT_SECRET"];
    @redirect_uri = ENV["GOOGLE_REDIRECT_URI"];
    @scopes = ENV["GOOGLE_SCOPES"];
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

  def invite_user_to_workspace(email, name)
    require 'google/apis/admin_directory_v1'
    
    begin
      Rails.logger.info "Starting the user invitation process"
      
      # Initialize the Directory Service
      service = Google::Apis::AdminDirectoryV1::DirectoryService.new
      service.client_options.application_name = 'Entitle'
      service.authorization = @access_token  # Use instance variable @access_token
    
      # Create a new user object without specifying password
      user_object = Google::Apis::AdminDirectoryV1::User.new(
        primary_email: email,
        name: Google::Apis::AdminDirectoryV1::UserName.new(
          given_name: name,
          family_name: "User"
        ),
        password: "Test@123!",
        org_unit_path: "/"  # Specify the organizational unit path if needed
      )
    
      # Insert the new user
      result = service.insert_user(user_object)
      customer_id = result.customer_id
      Rails.logger.info "User #{email} invited successfully with customer_id: #{customer_id}."

      return customer_id
    rescue => e
      if e.message == "Unauthorized"
        new_access_token_from_refresh_token(@refresh_token)
        invite_user_to_workspace(email, name)
      else
        Rails.logger.error "Error inviting user #{email}: #{e.message}"
        raise "Error inviting user #{email}: #{e.message}"
      end
    end
  end

  def new_access_token_from_refresh_token(refresh_token)
    response = RestClient.post 'https://oauth2.googleapis.com/token', { refresh_token: refresh_token, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "refresh_token" }
    data = JSON.parse(response.body);
    update_access_token_in_database(refresh_token, data['access_token'])
    @access_token = data['access_token']
    return @access_token
  end
  
  def update_access_token_in_database(refresh_token, new_access_token)
    company_integration = CompanyIntegration.where(refresh_token: refresh_token, integration_id: 4, company_id: @company_id).first
    company_integration.update(access_token: new_access_token)
  end

  # def revoke_token(token_to_revoke)
  #   begin
  #     response = RestClient.post 'https://oauth2.googleapis.com/revoke',
  #                                token: token_to_revoke,
  #                                client_id: @client_id,
  #                                client_secret: @client_secret
  #     # Assuming successful revocation returns an empty response with HTTP 200 status
  #     if response.code == 200
  #       Rails.logger.info "Token revoked successfully."
  #       return true
  #     else
  #       Rails.logger.error "Failed to revoke token. Response code: #{response.code}, Body: #{response.body}"
  #       return false
  #     end
  #   rescue => e
  #     Rails.logger.error "Error revoking token: #{e.message}"
  #     return false
  #   end
  # <a href="/integration/revoke_integration/<%= integration&.id %>" class="btn btn-primary" >Disconnect</a>
  # end

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
        new_access_token_from_refresh_token(@refresh_token)
        delete_workspace_user(primary_email)
      else
        Rails.logger.error "Error inviting user #{primary_email}: #{e.message}"
        raise "Error inviting user #{primary_email}: #{e.message}"
      end
    end
  end

  def add_user_to_group(email, name)
    require 'google/apis/admin_directory_v1'
    
    begin
      Rails.logger.info "Starting the process to add user #{email} to Entitle Group"
      
      # Initialize the Directory Service
      service = Google::Apis::AdminDirectoryV1::DirectoryService.new
      service.client_options.application_name = 'Entitle'
      service.authorization = @access_token  # Use instance variable @access_token
      
      # Create a new group member object
      member = Google::Apis::AdminDirectoryV1::Member.new(
        email: email,
        role: name
      )
      
      # Insert the member to the group
      result = service.insert_member("entitlegroupemail@youcanthave2spfrecords.com", member)
      Rails.logger.info "User #{email} added to group entitle successfully."
      send_email(email, 'You have been added to a new group entitle', 'Hello, you have been successfully added to the group.')
      return result
    rescue => e
      if e.message == "Unauthorized"
        new_access_token_from_refresh_token(@refresh_token)
        add_user_to_group(email, "entitle")
      else
        Rails.logger.error "Error adding user #{email} to group entitle: #{e.message}"
        raise "Error adding user #{email} to group entitle: #{e.message}"
      end
    end
  end

  def send_email(to, subject, body_text)
    # Initialize the Gmail API
    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
  
    message = Mail.new do
      from    'your-email@yourdomain.com'
      to      to
      subject subject
      body    body_text
    end
  
    # Encode the message in base64url format
    encoded_message = message.to_s
    encoded_message = encoded_message.gsub(/(\r\n|\n|\r)/, "\r\n")
    encoded_message = Base64.urlsafe_encode64(encoded_message)
  
    raw = Google::Apis::GmailV1::Message.new(raw: encoded_message)
    service.send_user_message('me', raw)
  end
  

end
