class IntegrationController < ApplicationController
  before_action :set_service, only: %i[authenticate google_workspace_callback microsoft_callback dropbox_callback]

  def index
    @integrations = Integration.all
  end

  def google_workspace_callback
    begin
      data = @google.generate_token_by_code(params["code"]);
      add_company_integration(current_user&.company_id,params["state"],data["access_token"],data["refresh_token"]);
      redirect_to integration_index_path	, notice: 'Successfully authenticated with Google.', alert: "success"
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def microsoft_callback
    begin
      access_token = @microsoft.generate_token(params["tenant"]);
      add_company_integration(current_user&.company_id,params["state"],access_token,access_token);
      redirect_to integration_index_path	, notice: 'Successfully authenticated with microsoft.', alert: "success"
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def dropbox_callback
    begin
      data = @dropbox.generate_token(params["code"])
      add_company_integration(current_user&.company_id,params["state"],data["access_token"],data["refresh_token"]);
      redirect_to integration_index_path	, notice: 'Successfully authenticated with Dropbox.', alert: "success"
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
    
  end

  def authenticate
    integration_id = params["integration_id"]
    case integration_id.to_s
      when "1"
        # for microsoft
        microsoft_auth_url = @microsoft.authenticate(integration_id)
        redirect_to(microsoft_auth_url,allow_other_host: true)
      when "2"
        # for AWS
        redirect_to integration_index_path	, notice: "AWS integration not added!!", alert: "danger"
      when "3"
        # for Azure
        redirect_to integration_index_path	, notice: "Azure integration not added!!", alert: "danger"
      when "4"
        # for Google workspace
        # google_auth_url = @google.get_google_auth_url(integration_id)
        # redirect_to(google_auth_url,allow_other_host: true)
        redirect_to integration_index_path	, notice: "Google Cloud integration not added!!", alert: "danger"
      when "5"
        # for Quickbooks
        redirect_to integration_index_path	, notice: "Quickbooks integration not added!!", alert: "danger"
      when "6"
        # for Dropbox
        dropbox_auth_url = @dropbox.authenticate(integration_id);
        redirect_to(dropbox_auth_url,allow_other_host: true)
      when "7"
        # for Google Cloud
        redirect_to integration_index_path	, notice: "Google Cloud integration not added!!", alert: "danger"
      when "8"
        # for Box
        redirect_to integration_index_path	, notice: "Box integration not added!!", alert: "danger"
      else
        redirect_to integration_index_path	, notice: "Please select valid integration!!", alert: "danger" 
    end
  end

  private
  def set_service
    @google = Google::new()
    @microsoft = Microsoft::new()
    @dropbox = DropBox::new()
  end
  def add_company_integration(company_id, integration_id,access_token, refresh_token)
    company_inetgration = CompanyIntegration.new
    company_inetgration[:company_id] = company_id;
    company_inetgration[:integration_id] = integration_id;
    company_inetgration[:access_token] = access_token;
    company_inetgration[:refresh_token] = refresh_token;
    company_inetgration.save!
  end
end
