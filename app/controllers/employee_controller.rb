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
        p employee_params
        @employee.update(employee_params)
        store_activity_log(@employee.id, current_user.id, "updated details")
        redirect_to edit_employee_path(@employee[:id]), notice: 'Employee updated successfully!!', alert: "success"
      rescue => error
        p error.message
        redirect_to edit_employee_path(@employee[:id]), notice: error.message, alert: "danger"
      end
    end

    # save employee
    def create
      begin
        employee = Employee.new(employee_params)
        employee.company_id = current_user.company_id;
        
        if employee.save!
          # invite user on workspace
          # @google.create_user(employee_params[:email], employee_params[:name], employee_params[:name])
          # invite user on microsoft
          # @microsoft.invite_user(employee_params[:email], employee_params[:name]);
          # invite user on dropbox
          # @dropbox.invite_member(employee_params[:email], employee_params[:name])
          store_activity_log(employee.id, current_user.id, "Account created")
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
    access_token = google_workspace_int.access_token if google_workspace_int.present?
    @google = Google::new(access_token)
    access_token = nil
    access_token = microsoft_integration.access_token if microsoft_integration.present?
    @microsoft = Microsoft::new(access_token)
    access_token = nil
    access_token = dropbox_integration.access_token if dropbox_integration.present?
    @dropbox = DropBox::new(access_token)
  end
end
