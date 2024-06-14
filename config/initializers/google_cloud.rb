require 'google/apis/admin_directory_v1'

Google::Apis::RequestOptions.default.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(Rails.root.join(ENV['SERVICE_FILE'])),
  scope: ['https://www.googleapis.com/auth/admin.directory.user', 'https://www.googleapis.com/auth/admin.directory.group']
)