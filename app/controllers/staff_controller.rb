class StaffController < ApplicationController

  # show staff page
  def index
    @staff_list = User.joins(:role).all
  end

  # show add staff form
  def new
    @roles = Role.all
  end

  # save staff
  def create
    begin
      user = User.new(user_params)
      user.company_id = current_user.company_id;
      user.skip_password_validation = true;

      if user.save!
        redirect_to staff_index_path, notice: 'Staff registered successfully!!', alert: "success"
      else
        redirect_to new_staff_path, notice: 'Something went wrong!!', alert: "danger"
      end
    rescue => error
      p error.message
      redirect_to new_staff_path, notice: error.message, alert: "danger"
    end
  end

  def show
  end

  def edit

  end

  def update
    
  end

  # delete staff
  def destroy
    User.destroy_by(id: delete_user_params[:id])
    redirect_to staff_index_path, notice: 'Staff deleted successfully!!', alert: "success"
  end


  private
    def user_params
        params.require(:user).permit(:name, :email, :role_id, :phone, :joining_date)
    end
    def delete_user_params
      puts "params ==========="
      puts params.inspect
      params.permit(:id)
    end
end
