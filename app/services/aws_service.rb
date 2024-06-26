require 'aws-sdk-iam' # Ensure you have aws-sdk-iam gem installed

class AwsService
  def initialize
    aws_credentials = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )

    @iam_client = Aws::IAM::Client.new(
      credentials: aws_credentials,
      region: ENV['AWS_REGION']
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
  rescue Aws::IAM::Errors::ServiceError => e
    Rails.logger.error("Failed to create IAM user: #{e.message}")
    raise
  end

  def delete_user(user_name)
    @iam_client.delete_login_profile(user_name: user_name)
    @iam_client.delete_user(user_name: user_name)
  rescue Aws::IAM::Errors::ServiceError => e
    Rails.logger.error("Failed to delete IAM user: #{e.message}")
    raise
  end

end