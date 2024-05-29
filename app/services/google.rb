require 'rest-client'
require 'json'

class Google
  def initialize(client_id, client_secret, redirect_uri, scopes)
    @client_id = client_id;
    @client_secret = client_secret;
    @redirect_uri = redirect_uri;
    @scopes = scopes;
  end

  def get_google_auth_url(integrtaion_id)
    @google_auth_url = "https://accounts.google.com/o/oauth2/v2/auth?scope="+@scopes+"&access_type=offline&include_granted_scopes=true&response_type=code&state="+integrtaion_id+"&redirect_uri="+@redirect_uri+"&client_id="+@client_id+"&service=lso&o2v=2&ddm=0"
  end

  def generate_token_by_code(code)
    response = RestClient.post 'https://oauth2.googleapis.com/token', { code: code, client_id: @client_id, client_secret: @client_secret, redirect_uri: @redirect_uri, grant_type: "authorization_code" }
    data = JSON.parse(response.body);
  end
end
