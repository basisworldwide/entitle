class IntegrationController < ApplicationController
  before_action :set_service, only: %i[authenticate google_workspace_callback microsoft_callback dropbox_callback revoke_integration quickbook_callback]
  before_action :initialize_slack_integration, only: %i[initiate_slack slack]

  def index
    @integrations = Integration.all
  end

  def initiate_slack

  end

  def slack
    @company_integration['access_token'] =  company_inetgration_params[:access_token]
    @company_integration['slack_channels'] =  company_inetgration_params[:slack_channels]
    @company_integration['refresh_token'] =  ""
    @company_integration.save!
  end

  def google_workspace_callback
    begin
      data = @google.generate_token_by_code(params["code"]);
      # refresh token only comes at once when the user is authenticated
      add_company_integration(current_user&.company_id,params["state"], data["access_token"], data["refresh_token"]);
      redirect_to integration_index_path	, notice: 'Successfully authenticated with Google.', alert: "success"
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def box_callback
    begin
      p params
      redirect_to integration_index_path	, notice: 'Successfully authenticated with Box.', alert: "success"
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
        google_auth_url = @google.get_google_auth_url(integration_id)
        redirect_to(google_auth_url, allow_other_host: true)
        # redirect_to integration_index_path	, notice: "Google Workspace integration not added!!", alert: "danger"
      when "5"
        # for Quickbooks
        redirect_to integration_index_path	, notice: "Quickbooks integration not added!!", alert: "danger"
      when "6"
        # for Dropbox
        dropbox_auth_url = @dropbox.authenticate(integration_id);
        redirect_to(dropbox_auth_url,allow_other_host: true)
      when "7"
        # for Google Cloud
        google_auth_url = @google.get_google_auth_url(integration_id)
        redirect_to(google_auth_url, allow_other_host: true)
        # redirect_to integration_index_path	, notice: "Google Cloud integration not added!!", alert: "danger"
      when "8"
        # for Box
        redirect_to integration_index_path	, notice: "Box integration not added!!", alert: "danger"
      when "9"
        # for Slack
        redirect_to initiate_slack_integration_path(9)
      else
        redirect_to integration_index_path	, notice: "Please select valid integration!!", alert: "danger" 
    end
  end

  def revoke_integration
    integration_id = params["integration_id"]
    case integration_id.to_s
      when "4"
        @google.revoke_token()
      when "6"
        @dropbox.revoke_dropbox_token()
      when "7"
        @google.revoke_token()
      end
    redirect_to integration_index_path 
  end

  private
  def company_inetgration_params
    params.require(:company_integration).permit(:access_token, :slack_channels)
  end
  def set_service
    google_workspace_int = current_user.company.company_integration.where(integration_id: 4).first
    dropbox_integration = current_user.company.company_integration.where(integration_id: 6).first
    google_cloud_int = current_user.company.company_integration.where(integration_id: 7).first
    if google_workspace_int.present?
      access_token = google_workspace_int.access_token
      @google = Googleworkspace.new(access_token, google_workspace_int.refresh_token, company_id: google_workspace_int.company_id)
    else
      @google = Googleworkspace.new()
    end
    @microsoft = Microsoft::new()
    @dropbox = DropBox::new()
    if dropbox_integration.present?
      access_token = dropbox_integration.access_token if dropbox_integration.present?
      @dropbox = DropBox::new(access_token, dropbox_integration.company_id)
    else
      @dropbox = DropBox::new()
    end
    if google_cloud_int.present?
      access_token = google_workspace_int.access_token
      @google_cloud = Googleworkspace.new(access_token, google_cloud_int.refresh_token, company_id: google_cloud_int.company_id)
    else
      @google_cloud = Googleworkspace.new()
    end
  end

  def initialize_slack_integration
    @company_integration = CompanyIntegration.new
    @company_integration[:company_id] = current_user&.company_id;
    @company_integration[:integration_id] = 9;
  end

  def add_company_integration(company_id, integration_id,access_token, refresh_token, quickbook_realm_id=nil)
    company_integration = CompanyIntegration.new
    company_integration[:company_id] = company_id;
    company_integration[:integration_id] = integration_id;
    company_integration[:access_token] = access_token;
    company_integration[:refresh_token] = refresh_token;
    company_integration.save!
  end
end
