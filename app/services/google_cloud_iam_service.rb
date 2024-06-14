require 'google/apis/admin_directory_v1'

class GoogleCloudIamService
  Directory = Google::Apis::AdminDirectoryV1

  def initialize
    @client = Directory::DirectoryService.new
  end

  def create_user(email, first_name, last_name, password)
    user = Directory::User.new(
      primary_email: email,
      name: Directory::UserName.new(
        given_name: first_name,
        family_name: last_name
      ),
      password: password,
      change_password_at_next_login: true
    )
    @client.insert_user(user)
  rescue Google::Apis::ClientError => e
    Rails.logger.error("Google Cloud Directory API error: #{e.message}")
    nil
  end

  def assign_role(email, role)
    # Need to implement the assign
  end
end