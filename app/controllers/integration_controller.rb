class IntegrationController < ApplicationController
  before_action :set_service, only: %i[authenticate google_workspace_callback]

  def index
    @integrations = Integration.all
  end

  def google_workspace_callback
    begin
      data = @google.generate_token_by_code(params["code"]);
      company_inetgration = CompanyIntegration.new
      company_inetgration[:company_id] = current_user&.company_id;
      company_inetgration[:integration_id] = params["state"];
      company_inetgration[:access_token] = data["access_token"];
      company_inetgration[:refresh_token] = data["refresh_token"];
      company_inetgration.save!
      redirect_to integration_index_path	, notice: 'Successfully authenticated with Google.', alert: "success"
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def authenticate
    google_auth_url = @google.get_google_auth_url(params["integration_id"])
    redirect_to(google_auth_url,allow_other_host: true)
  end

  private
  def set_service
    @google = Google::new(ENV["GOOGLE_CLIENT_ID"],ENV["GOOGLE_CLIENT_SECRET"],ENV["GOOGLE_REDIRECT_URI"],ENV["GOOGLE_SCOPES"])
  end
end
