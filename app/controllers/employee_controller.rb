class EmployeeController < ApplicationController
    include ActivityLogConcern
    before_action :find_employee, only: %i[show update destroy new edit]
    before_action :find_company_integrations, only: %i[new edit show]
    before_action :add_start_end_date_in_integrations, only: %i[create update]
    before_action :set_service, only: %i[create update destroy]
    
    def index
      @employees = Employee.where(company_id: current_user.company_id)
    end

    def new
      @employee = Employee.new
      intialize_employee_integrations
    end

    def show
    end

    def edit
      intialize_employee_integrations
    end

    def update
      begin
        @employee.update(filtered_employee_params)
        store_activity_log(@employee.id, current_user.id, "updated details")
        filtered_employee_params["employee_integrations_attributes"]&.each do |key, integration|
          if integration["is_integration_deleted"] == "1"
            # assign permission
            assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], @employee[:id],integration["account_type"],integration["is_integration_deleted"],integration["integration_user_id"], filtered_employee_params["secondary_email"])
          elsif integration["is_permission_assigned"] == "1"
            # remove access
            assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], @employee[:id],integration["account_type"],0,nil,filtered_employee_params["secondary_email"])
          end
        end
        redirect_to employee_index_path, notice: 'Employee updated successfully!!', alert: "success"
        # redirect_to edit_employee_path(@employee[:id]), notice: 'Employee updated successfully!!', alert: "success"
      rescue => error
        redirect_to employee_index_path, notice: error.message, alert: "danger"
      end
    end

    # save employee
    def create
      begin
        employee = Employee.new(filtered_employee_params)
        employee.company_id = current_user.company_id;      
        
        if employee.save!
          store_activity_log(employee.id, current_user.id, "Account created")
          filtered_employee_params["employee_integrations_attributes"]&.each do |key, integration|
            if integration["is_permission_assigned"] == "1"
              assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], employee[:id],integration["account_type"],0,nil, filtered_employee_params["secondary_email"])
            end
          end
          redirect_to employee_index_path, notice: 'Employee registered successfully!!', alert: "success"
        else
          redirect_to employee_index_path, notice: 'Something went wrong!!', alert: "danger"
        end
      rescue => error
        if error.message == "SQLite3::ConstraintException: UNIQUE constraint failed: employees.email"
          redirect_to employee_index_path, notice: "Email Already Exists", alert: "danger"
        else
          redirect_to employee_index_path, notice: error.message, alert: "danger"
        end
      end
    end


  # delete employee
  def destroy
    employee_integration = EmployeeIntegration.where(employee_id: @employee.id, integration: 4).first
    if employee_integration.present? && employee_integration.integration_user_id.present?
      @google.delete_workspace_user(@employee.email)
    end
    @employee.destroy;
    redirect_to employee_index_path, notice: 'Employee deleted successfully!!', alert: "success"
  end

    private
    def employee_params
        params.require(:employee).permit(:name, :email, :designation, :phone, :joining_date, :employee_id, :start_date, :end_date, :image, :secondary_email, :employee_integrations_attributes => [
          :id,
          :employee_id,
          :is_permission_assigned,
          :is_integration_deleted,
          :integration_user_id,
          :integration_id,
          :account_type,
          :start_date,
          :end_date
        ])
    end

    def add_start_end_date_in_integrations
      params["employee"]["employee_integrations_attributes"]&.each do |ind, attributes|
        attributes["start_date"] = params["integration_start_date"]
        attributes["end_date"] = params["integration_end_date"]
      end
    end

    def find_employee
      @employee = Employee.find(params[:id]) if params[:id].present?
    end

    def find_company_integrations
      @company_integrations = CompanyIntegration.where(company_id: current_user.company_id)
    end

    def intialize_employee_integrations
      @company_integrations.each do |integration|
        has_integration = @employee.id.present? && @employee.employee_integrations.where(integration_id: integration.integration_id)
        if has_integration.blank?
          @employee.employee_integrations.build(integration_id: integration.integration_id)
        end
      end
    end

    def filtered_employee_params
      if !employee_params["employee_integrations_attributes"].nil?
        filtered_params = employee_params["employee_integrations_attributes"].select { |key, param| param["is_permission_assigned"] == "1" || param["is_integration_deleted"] == "1"  }
        employee_params.merge(employee_integrations_attributes: filtered_params)
      else
        employee_params
      end
    end

    def set_data
      @integrations = Integration.all
      @show_integrations = false
    end

  def set_service
    access_token = nil
    # for microsoft
    microsoft_app_details = AppRegisterationDetail.where(integration_id: 1, company_id: current_user&.company_id).first
    microsoft_integration = current_user.company.company_integration.where(integration_id: 1).first
    @microsoft = Microsoft::new(microsoft_integration.access_token, app_details: microsoft_app_details) if microsoft_integration.present?
    # for aws
    aws_int = current_user.company.company_integration.where(integration_id: 2).first
    @aws = AwsService::new(aws_int.aws_access_key_id, aws_int.aws_secret_access_key, aws_int.aws_region) if aws_int.present?
    # for google workspace
    google_app_details = AppRegisterationDetail.where(integration_id: 4, company_id: current_user&.company_id).first
    google_workspace_int = current_user.company.company_integration.where(integration_id: 4).first
    @google = Googleworkspace.new(google_workspace_int.access_token, google_workspace_int.refresh_token, current_user&.company_id, app_details: google_app_details) if google_workspace_int.present?
    # for quickbooks
    # for drop box
    dropbox_app_details = AppRegisterationDetail.where(integration_id: 6, company_id: current_user&.company_id).first
    dropbox_integration = current_user.company.company_integration.where(integration_id: 6).first
    @dropbox = DropBox::new(dropbox_integration.access_token, company_id: current_user&.company_id, app_details: dropbox_app_details) if dropbox_integration.present?
    #for box
    box_app_details = AppRegisterationDetail.where(integration_id: 8, company_id: current_user&.company_id).first
    box_int = current_user.company.company_integration.where(integration_id: 8).first
    @box = Box.new(box_int.access_token, box_int.refresh_token, current_user&.company_id, app_details: box_app_details) if box_int.present?
    #for slack
    slack_integration = current_user.company.company_integration.where(integration_id: 9).first
    access_token = slack_integration.access_token if slack_integration.present?
    channels = slack_integration.slack_channels.presence || nil  if slack_integration.present?
    @slack = SlackService::new(access_token, channels) if slack_integration.present?
  end

  def update_integration_user_id(employee_id, integration_id, integration_user_id)
    employee_integration = EmployeeIntegration.where(employee_id: employee_id, integration_id: integration_id)
    if employee_integration.present?
      employee_integration.update(integration_user_id: integration_user_id)
    end
  end

  # assign permission based on interations
  def assign_remove_permission(integration_id, name, email, employee_id,account_type, is_integration_deleted, integration_user_id=nil, secondary_email=nil)
    activity_log_msg = "";
    case integration_id.to_s
      when "1"
        if is_integration_deleted == 0
          # invite user on microsoft
          data = nil
          if account_type == "microsoft"
            data = @microsoft.invite_user(email, name, current_user&.company_id,integration_id);
          elsif account_type == "teams"
            data = @microsoft.invite_user_to_teams(email, name, current_user&.company_id,integration_id);
          elsif account_type == "share_point"
            data = @microsoft.invite_user_to_sharepoint_site(email, name, current_user&.company_id,integration_id)
          end
          # store user id from microsoft so we can remove that user or there permission
          if !data
            remove_employee_integration(employee_id, integration_id);
            raise "Something went wrong while assigning Microsoft permission. Please try again"
          end
          update_integration_user_id(employee_id, integration_id,data["invitedUser"]["id"]);
          activity_log_msg = "has added <b>Microsoft Office 365</b> account access."
        else
          # remove access from employee
          if integration_user_id.present?
            if account_type == "microsoft" || account_type == "sharepoint"
              @microsoft.remove_access(integration_user_id,current_user&.company_id,integration_id);
            elsif account_type == "teams"
              @microsoft.delete_team_member(integration_user_id,current_user&.company_id,integration_id);
            end
            @microsoft.remove_access(integration_user_id,current_user&.company_id,integration_id);
            activity_log_msg = "has removed <b>Microsoft Office 365</b> account access."
            remove_employee_integration(employee_id, integration_id);
          end
        end
      when "2"
        # invite user on AWS
        if is_integration_deleted == 0
          data = @aws.create_user(email);
          if data.include?("Failed to create IAM user:") || data.include?("Failed to delete IAM user:")
            remove_employee_integration(employee_id, integration_id);
            raise "Something went wrong while assigning AWS permission. Please try again. #{data}"
          end
          update_integration_user_id(employee_id, integration_id,nil);
          activity_log_msg = "has added <b>AWS</b> account access."
        else
          # remove access from employee
          if integration_user_id.present?
            @aws.delete_user(email);
            activity_log_msg = "has removed <b>AWS</b> account access."
            remove_employee_integration(employee_id, integration_id);
          end
        end
      when "3"
        # invite user on Azure
      when "4"
        # invite user on Google workspace

        if is_integration_deleted == 0
          # invite user on Google workspace
          data = nil
          if account_type == "google_workspace"
            data = @google.invite_user_to_workspace(email, name, secondary_email);
          elsif account_type == "google_cloud"
            data = @google.invite_user_to_cloud(email);
          end
          if data.status_code != 200
            remove_employee_integration(employee_id, integration_id);
            raise "Error inviting user #{email}: #{data.message}"
          end
          update_integration_user_id(employee_id, integration_id, data);
          activity_log_msg = "has added <b>Google Workspace</b> account access."
        else
          if integration_user_id.present?
            if account_type == "google_workspace"
              @google.delete_workspace_user(email);
            elsif account_type == "google_cloud"
              data = @google_cloud.delete_cloud_user(email);
            end
            activity_log_msg = "has removed <b>Google Workspace</b> account access."
          end
          remove_employee_integration(employee_id, integration_id);
        end
      when "5"
          # invite user on Quickbooks
      when "6"
        if is_integration_deleted == 0
          # invite user on dropbox
          data = @dropbox.invite_member(email, name, current_user&.company_id, integration_id,account_type)
          if !data.present?
            remove_employee_integration(employee_id, integration_id)
            raise "Something went wrong while assigning Dropbox permission. Please try again"
          elsif data[".tag"] == "complete" && data["complete"][0][".tag"] == "team_license_limit"
            remove_employee_integration(employee_id, integration_id)
            raise "Dropbox team license limit exceeded"
          elsif data[".tag"] == "complete" && data["complete"][0][".tag"] == "user_creation_failed"
            remove_employee_integration(employee_id, integration_id)
            raise "Something went wrong while trying to invite user on Dropbox"
          end
          # store team member id from dropbox so we can remove that user or there permission
          update_integration_user_id(employee_id, integration_id,data["complete"][0]["profile"]["team_member_id"]);
          activity_log_msg = "has added <b>Dropbox</b> account access."
        else 
          # remove access from employee
          if integration_user_id.present?
            @dropbox.remove_access(integration_user_id, current_user&.company_id, integration_id);
            activity_log_msg = "has removed <b>Dropbox</b> account access."
            remove_employee_integration(employee_id, integration_id);
          end
        end
      when "7"
        # invite user on Google Cloud
      when "8"
        # invite user on Box
        if is_integration_deleted == 0
          data = @box.create_box_user(email, name);
          if data.include?("Error")
            remove_employee_integration(employee_id, integration_id);
            raise "Error inviting user #{email}: #{data}"
          end
          update_integration_user_id(employee_id, integration_id, data);
          activity_log_msg = "has added <b>Box</b> account access."
        else
          if integration_user_id.present?
            @box.delete_user(integration_user_id);
            activity_log_msg = "has removed <b>Box</b> account access."
          end
          remove_employee_integration(employee_id, integration_id);
        end
      when "9"
        # invite user on Slack
        if is_integration_deleted == 0
          # invite user on dropbox
          data = @slack.invite_member(email)
          # store team member id from dropbox so we can remove that user or there permission
          update_integration_user_id(employee_id, integration_id,data["complete"][0]["profile"]["team_member_id"]);
          activity_log_msg = "has added <b>Dropbox</b> account access."
        else 
          # remove access from employee
         
        end
      else
        raise "Invalid integration id"
    end
    if activity_log_msg != ""
      store_activity_log(employee_id, current_user.id, activity_log_msg)
    end
  end

  def remove_employee_integration(employee_id, integration_id)
    employee_integration = EmployeeIntegration.where(employee_id: employee_id, integration_id: integration_id).first
    employee_integration&.destroy
  end
end
