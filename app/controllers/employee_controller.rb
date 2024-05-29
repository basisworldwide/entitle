class EmployeeController < ApplicationController
    include ActivityLogConcern
    before_action :find_employee, only: %i[show update destroy new edit]
    before_action :find_company_integrations, only: %i[new edit show]
    before_action :add_start_end_date_in_integrations, only: %i[create update]
    
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
end
