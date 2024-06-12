require 'boxr'

class Box
    
    def initialize(access_token=nil, refresh_token = nil)
        token_refresh_callback = lambda {|access, refresh, identifier| save_box_token(access, refresh)}
        @client = Boxr::Client.new(access_token,
                                  refresh_token: refresh_token,
                                  client_id: client_id,
                                  client_secret: client_secret,
                                  &token_refresh_callback)
    end

    def save_box_token 
    end
  
    def invite(name, email)
        @client.create_user(name, email)
    end

  end