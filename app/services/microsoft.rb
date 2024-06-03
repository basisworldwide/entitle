require "microsoft_kiota_authentication_oauth"
require "microsoft_graph_core"  
require "microsoft_graph"
class Microsoft

  monkey_patch = Module.new do
    def set_content_from_parsable(request_adapter, content_type, values)
        writer = request_adapter.get_serialization_writer_factory().get_serialization_writer(content_type)
        @headers.try_add(self.class.class_variable_get(:@@content_type_header), content_type)
        if values != nil && values.kind_of?(Array)
          @content = writer.write_collection_of_object_values(nil, values).map(&:get_serialized_content).to_json
        else
          @content = writer.write_object_value(nil, values).get_serialized_content
        end
    end
  end
  
  MicrosoftKiotaAbstractions::RequestInformation.prepend(monkey_patch)

  def initialize(access_token=nil)
    @client_id = ENV["MICROSOFT_CLIENT_ID"];
    @tenant_id = ENV["MICROSOFT_TENANT_ID"];
    @client_secret = ENV["MICROSOFT_CLIENT_SECRET"];
    @redirect_uri = ENV["MICROSOFT_REDIRECT_URI"];
    @access_token = access_token;
  end

  def authenticate
    begin
      new_invitation = MicrosoftGraph::Models::Invitation.new()
      context = MicrosoftKiotaAuthenticationOAuth::ClientCredentialContext.new(@tenant_id, @client_id, @client_secret)
      authentication_provider = MicrosoftGraphCore::Authentication::OAuthAuthenticationProvider.new(context, nil, ["https://graph.microsoft.com/.default"])
    
      adapter = MicrosoftGraph::GraphRequestAdapter.new(authentication_provider)
      client = MicrosoftGraph::GraphServiceClient.new(adapter)
      new_invitation.invited_user_email_address = "lbansal.75way@gmail.com"
      new_invitation.invite_redirect_url = "https://1e0a-223-178-208-220.ngrok-free.app"
      # p new_invitation
      x = client.invitations.post(new_invitation).resume
      p "=-=-=-====================data====================="
      p x.body.inspect
    rescue MicrosoftGraph::Models::ODataErrorsODataError => e
      p "Error code: #{e.error.code}"
      p "Error message: #{e.error.message}"
      e.error.inner_error && p("Inner error: #{e.error.inner_error.inspect}")
    rescue Exception => e
      p e
      p e.inspect
    end
    return true
  end

end