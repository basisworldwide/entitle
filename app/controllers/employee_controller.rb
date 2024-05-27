class EmployeeController < ApplicationController
    before_action :find_employee, only: %i[show edit update destroy]

    def index
      @employees = Employee.where(company_id: current_user.company_id)
    end

    def new
      
    end

    def popup
      
    end

    def show
      
    end

    def edit

    end

    def update
      begin
        @employee.update(employee_params)
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
        params.require(:employee).permit(:name, :email, :designation, :phone, :joining_date, :employee_id, :start_date, :end_date)
    end

    def find_employee
      @employee = Employee.find(params[:id]) if params[:id].present?
    end
end
