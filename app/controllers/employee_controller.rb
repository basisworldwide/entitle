class EmployeeController < ApplicationController
    include ActivityLogConcern
    before_action :find_employee, only: %i[show update destroy new edit]
    before_action :find_company_integrations, only: %i[new edit show]
    before_action :add_start_end_date_in_integrations, :set_service, only: %i[create update]
    
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
            assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], @employee[:id],integration["account_type"],integration["is_integration_deleted"],integration["integration_user_id"])
          elsif integration["is_permission_assigned"] == "1"
            # remove access
            assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], @employee[:id],integration["account_type"],0,nil)
          end
        end
        redirect_to edit_employee_path(@employee[:id]), notice: 'Employee updated successfully!!', alert: "success"
      rescue => error
        p error.message
        redirect_to edit_employee_path(@employee[:id]), notice: error.message, alert: "danger"
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
              assign_remove_permission(integration["integration_id"], filtered_employee_params["name"], filtered_employee_params["email"], employee[:id],integration["account_type"],0,nil)
            end
          end
          redirect_to employee_index_path, notice: 'Employee registered successfully!!', alert: "success"
        else
          redirect_to new_employee_path, notice: 'Something went wrong!!', alert: "danger"
        end
      rescue => error
        redirect_to new_employee_path, notice: error.message, alert: "danger"
      end
    end


  # delete employee
  def destroy
    @employee.destroy;
    redirect_to employee_index_path, notice: 'Employee deleted successfully!!', alert: "success"
  end

    private
    def employee_params
        params.require(:employee).permit(:name, :email, :designation, :phone, :joining_date, :employee_id, :start_date, :end_date, :image, :employee_integrations_attributes => [
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
      p params
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
    # for google workspace
    google_workspace_int = current_user.company.company_integration.where(integration_id: 4).first
    # for microsoft
    microsoft_integration = current_user.company.company_integration.where(integration_id: 1).first
    # for drop box
    dropbox_integration = current_user.company.company_integration.where(integration_id: 6).first
    slack_integration = current_user.company.company_integration.where(integration_id: 9).first
    access_token = google_workspace_int.access_token if google_workspace_int.present?
    # @google = Google::new(access_token)
    access_token = nil
    access_token = microsoft_integration.access_token if microsoft_integration.present?
    @microsoft = Microsoft::new(access_token)
    access_token = nil
    access_token = dropbox_integration.access_token if dropbox_integration.present?
    @dropbox = DropBox::new(access_token)
    # access_token = nil
    # access_token = slack_integration.access_token 
    access_token = slack_integration.access_token
    channels = slack_integration.slack_channels.presence || nil  if slack_integration.present?
    @slack = SlackService::new(access_token, channels)
  end

  def update_integration_user_id(employee_id, integration_id, integration_user_id)
    employee_integration = EmployeeIntegration.where(employee_id: employee_id, integration_id: integration_id)
    if employee_integration.present?
      p employee_integration
      employee_integration.update(integration_user_id: integration_user_id)
    end
  end

  # assign permission based on interations
  def assign_remove_permission(integration_id, name, email, employee_id,account_type, is_integration_deleted, integration_user_id=nil)
    activity_log_msg = "";
    case integration_id.to_s
      when "1"
        if is_integration_deleted == 0
          # invite user on microsoft
          data = @microsoft.invite_user(email, name, current_user&.company_id,integration_id);
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
            @microsoft.remove_access(integration_user_id,current_user&.company_id,integration_id);
            activity_log_msg = "has removed <b>Microsoft Office 365</b> account access."
            remove_employee_integration(employee_id, integration_id);
          end
        end
        
      when "2"
        # invite user on AWS
      when "3"
        # invite user on Azure
      when "4"
        # invite user on Google workspace
      when "5"
        # invite user on Quickbooks
      when "6"
        if is_integration_deleted == 0
          # invite user on dropbox
          data = @dropbox.invite_member(email, name, current_user&.company_id, integration_id,account_type)
          p data
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
            @dropbox.remove_access(integration_user_id,current_user&.company_id,integration_id);
            activity_log_msg = "has removed <b>Dropbox</b> account access."
            remove_employee_integration(employee_id, integration_id);
          end
        end
        
      when "7"
        # invite user on Google Cloud
      when "8"
        # invite user on Box
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
