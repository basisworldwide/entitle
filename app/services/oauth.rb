module OAuth

    class Authentication

        attr_writer :client_id, :client_secret, :redirect_uri, :site, :scope

        def initialize(site, client_id, client_secret, redirect_uri, scope = "")
            @client_id = client_id
            @client_secret = client_secret
            @redirect_uri = redirect_uri
            @scope = scope
            @site = site
        end

        def create_client
            OAuth2::Client.new(
              @client_id, @client_secret,
              :site => @site,
              :token_url => "/o/oauth2/token",
              :authorize_url => "/o/oauth2/auth")
          end
      
          def set_authorize_url
            client = create_client
            client.auth_code.authorize_url(
              :redirect_uri => @redirect_uri,
              :access_type => "offline",
              :scope =>
                @scope)
          end

    end
end