require 'aws-sdk-iam' # Ensure you have aws-sdk-iam gem installed

class AwsService
  def initialize(access_key_id, secret_access_key, aws_region)
    aws_credentials = Aws::Credentials.new(
      access_key_id,
      secret_access_key
    )

    @iam_client = Aws::IAM::Client.new(
      credentials: aws_credentials,
      region: aws_region
    )
  end

  def create_user(user_name)
    @iam_client.create_user(user_name: user_name)
    @iam_client.wait_until(:user_exists, user_name: user_name)
    result = @iam_client.create_login_profile(
      password: "Test@123!",
      password_reset_required: true,
      user_name: user_name
    )
  rescue => e
    return "Failed to create IAM user: #{e.message}"
  end

  def delete_user(user_name)
    @iam_client.delete_login_profile(user_name: user_name)
    @iam_client.delete_user(user_name: user_name)
  rescue => e
    return "Failed to delete IAM user: #{e.message}"
  end

end