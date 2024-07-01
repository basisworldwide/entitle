class IntegrationController < ApplicationController
  before_action :set_service, only: %i[authenticate google_workspace_callback microsoft_callback dropbox_callback quickbook_callback box_callback]
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
      if params["code"].present?
        data = @google.generate_token_by_code(params["code"]);
        # refresh token only comes at once when the user is authenticated
        add_company_integration(current_user&.company_id,params["state"], data["access_token"], data["refresh_token"]);
        redirect_to integration_index_path	, notice: 'Successfully authenticated with Google.', alert: "success"
      else
        redirect_to integration_index_path, notice: 'Authorization with Google was canceled.', alert: "warning"
      end
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def box_callback
    begin
      if params["code"].present?
        data = @box.generate_token_by_code(params["code"]);
        add_company_integration(current_user&.company_id,params["state"], data["access_token"], data["refresh_token"]);
        redirect_to integration_index_path	, notice: 'Successfully authenticated with Box.', alert: "success"
      else
        redirect_to integration_index_path, notice: 'Authorization with Box was canceled.', alert: "warning"
      end
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
  end

  def microsoft_callback
    begin
      if params["tenant"].present?
        access_token = @microsoft.generate_token(params["tenant"]);
        add_company_integration(current_user&.company_id,params["state"],access_token,access_token);
        redirect_to integration_index_path	, notice: 'Successfully authenticated with microsoft.', alert: "success"
      else
        redirect_to integration_index_path, notice: 'Authorization with Microsoft was canceled.', alert: "warning"
      end
    rescue Exception => e
      if e.message == "404 Not Found"
        redirect_to integration_index_path
      else
        redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
      end
    end
  end

  def dropbox_callback
    begin
      if params["code"].present?
        data = @dropbox.generate_token(params["code"])
        add_company_integration(current_user&.company_id,params["state"],data["access_token"],data["refresh_token"]);
        redirect_to integration_index_path	, notice: 'Successfully authenticated with Dropbox.', alert: "success"
    else
      redirect_to integration_index_path, notice: 'Authorization with Google was canceled.', alert: "warning"
      end
    rescue Exception => e
      redirect_to integration_index_path	, notice: "Something went wrong!!", alert: "danger"
    end
    
  end

  def authenticate
    integration_id = params["integration_id"]
    app_details = AppRegisterationDetail.where(integration_id: integration_id, company_id: current_user&.company_id).first
    if app_details.nil? && [2,3,7,9].exclude?(integration_id.to_i)
      @integration_id_value = integration_id
      render :app_registeration_detail and return
    end
    case integration_id.to_s
      when "1"
        # for microsoft
        microsoft_auth_url = @microsoft.authenticate(integration_id)
        redirect_to(microsoft_auth_url,allow_other_host: true)
      when "2"
        # for AWS
        render :aws_detail
        # redirect_to integration_index_path	, notice: "AWS integration not added!!", alert: "danger"
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
        # google_auth_url = @google.get_google_auth_url(integration_id)
        # redirect_to(google_auth_url, allow_other_host: true)
        redirect_to integration_index_path	, notice: "Google Cloud integration not added!!", alert: "danger"
      when "8"
        # for Box
        box_auth_url = @box.authenticate(integration_id)
        redirect_to(box_auth_url, allow_other_host: true)
        # redirect_to integration_index_path	, notice: "Box integration not added!!", alert: "danger"
      when "9"
        # for Slack
        redirect_to initiate_slack_integration_path(9)
      else
        redirect_to integration_index_path	, notice: "Please select valid integration!!", alert: "danger" 
    end
  end

  def aws_details_added
    add_company_integration(current_user&.company_id,2,"","",nil, params["aws_access_key_id"], params["aws_secret_access_key"], params["aws_region"]);
    redirect_to integration_index_path	, notice: 'Successfully authenticated with AWS.', alert: "success"
  end

  def integration_data
    app_registeration_detail = AppRegisterationDetail.new(app_resigeration_params.merge(company_id: current_user&.company_id))
    app_registeration_detail.save!
    redirect_to integration_index_path	, notice: 'Now you can Authenticate with App.', alert: "success"
  end

  private
  def company_inetgration_params
    params.require(:company_integration).permit(:access_token, :slack_channels)
  end
  def set_service
    #for Microsoft
    microsoft_app_details = AppRegisterationDetail.where(integration_id: 1, company_id: current_user&.company_id).first
    microsoft_int = current_user.company.company_integration.where(integration_id: 1).first
    @microsoft = Microsoft::new(app_details: microsoft_app_details)
    #for Google
    google_app_details = AppRegisterationDetail.where(integration_id: 4, company_id: current_user&.company_id).first
    google_workspace_int = current_user.company.company_integration.where(integration_id: 4).first
    if google_workspace_int.present?
      access_token = google_workspace_int.access_token
      @google = Googleworkspace.new(access_token, google_workspace_int.refresh_token, company_id: current_user&.company_id, app_details: google_app_details)
    else
      @google = Googleworkspace.new(company_id: current_user&.company_id, app_details: google_app_details)
    end
    # for Dropbox
    drop_box_app_details = AppRegisterationDetail.where(integration_id: 6, company_id: current_user&.company_id).first
    dropbox_integration = current_user.company.company_integration.where(integration_id: 6).first
    if dropbox_integration.present?
      access_token = dropbox_integration.access_token if dropbox_integration.present?
      @dropbox = DropBox::new(access_token, dropbox_integration.company_id, app_details: drop_box_app_details)
    else
      @dropbox = DropBox::new(app_details: drop_box_app_details)
    end
    #for Box
    box_app_details = AppRegisterationDetail.where(integration_id: 8, company_id: current_user&.company_id).first
    p box_app_details
    box_int = current_user.company.company_integration.where(integration_id: 8).first
    if box_int.present?
      access_token = box_int.access_token
      @box = Box.new(access_token, box_int.refresh_token, company_id: box_int.company_id, app_details: box_app_details)
    else
      @box = Box::new(app_details: box_app_details)
    end
  end

  def initialize_slack_integration
    @company_integration = CompanyIntegration.new
    @company_integration[:company_id] = current_user&.company_id;
    @company_integration[:integration_id] = 9;
  end

  def add_company_integration(company_id, integration_id,access_token, refresh_token, quickbook_realm_id=nil, aws_access_key_id=nil, aws_secret_access_id=nil, aws_region=nil)
    company_integration = CompanyIntegration.new
    company_integration[:company_id] = company_id;
    company_integration[:integration_id] = integration_id;
    company_integration[:access_token] = access_token;
    company_integration[:refresh_token] = refresh_token;
    company_integration[:aws_access_key_id] = aws_access_key_id;
    company_integration[:aws_secret_access_key] = aws_secret_access_id;
    company_integration[:aws_region] = aws_region;
    company_integration.save!
  end

  def app_resigeration_params
    params.permit(:client_id, :redirect_uri, :group_id, :client_secret, :tenant_id, :scopes, :integration_id, :company_id)
  end

end
