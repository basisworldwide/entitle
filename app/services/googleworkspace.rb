require 'rest-client'
require 'json'

class Googleworkspace
  def initialize(access_token=nil)
    @client_id = ENV["GOOGLE_CLIENT_ID"];
    @client_secret = ENV["GOOGLE_CLIENT_SECRET"];
    @redirect_uri = ENV["GOOGLE_REDIRECT_URI"];
    @scopes = ENV["GOOGLE_SCOPES"];
    @access_token = access_token;
    @base_url = "https://admin.googleapis.com/admin/directory/v1"
  end

  def get_google_auth_url(integrtaion_id)
    @google_auth_url = "https://accounts.google.com/o/oauth2/v2/auth?scope="+@scopes+"&access_type=offline&include_granted_scopes=true&response_type=code&state="+integrtaion_id+"&redirect_uri="+@redirect_uri+"&client_id="+@client_id+"&service=lso&o2v=2&ddm=0"
  end

  def generate_token_by_code(code)
    response = RestClient.post 'https://oauth2.googleapis.com/token', { code: code, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "authorization_code" }
    data = JSON.parse(response.body);
    p data
    return data
  end

  # def invite_user_to_workspace(email, name)
  #   require 'google/apis/admin_directory_v1'
  #   require 'googleauth'
  #   begin
  #     Rails.logger.info "Starting the user invitation process"
      
  #     # Initialize the Directory Service
  #     service = Google::Apis::AdminDirectoryV1::DirectoryService.new
  #     service.client_options.application_name = 'Your Application Name'
  #     service.authorization = @access_token
  
  #     # Retrieve user details (give details of the access token account)
  #     # user_details = get_google_user_detail(@access_token)  
  
  #     # Create a new user object
  #     p "################################################################"
  #     p email
  #     p name
  #     user_object = Google::Apis::AdminDirectoryV1::User.new(
  #       primary_email: email,
  #       name: Google::Apis::AdminDirectoryV1::UserName.new(
  #         given_name: name,
  #         family_name: "user"
  #       ),
  #       password: "Test!234Us",
  #       org_unit_path: "/"
  #     )
  
  #     # Insert the new user
  #     service.insert_user(user_object)
      
  #     Rails.logger.info "User #{email} invited successfully."
  #   rescue Google::Apis::ClientError => e
  #     Rails.logger.error "Error inviting user #{email}: #{e.message}"
  #     raise "Error inviting user #{email}: #{e.message}"
  #   end
  # end
  

  # def get_google_user_detail(access_token)
  #   response = RestClient.get "https://www.googleapis.com/oauth2/v3/userinfo", {
  #                             'Authorization': "Bearer #{access_token}"
  #                             }
  #                             p response
  #   if response.code == 200 || response.code == 201
  #     return JSON.parse(response.body)
  #   end
  # end

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
      service.insert_user(user_object)
      
      Rails.logger.info "User #{email} invited successfully."
    rescue Google::Apis::ClientError => e
      Rails.logger.error "Error inviting user #{email}: #{e.message}"
      raise "Error inviting user #{email}: #{e.message}"
    end
  end
  

end
