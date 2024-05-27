class StaffController < ApplicationController

  before_action :find_staff, only: %i[show edit update]
  before_action :check_admin

  # show staff page
  def index
    @staff_list = User.where.not(email: current_user.email)
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
        # send reset password mail
        raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
        user.reset_password_token = hashed
        user.reset_password_sent_at = Time.now.utc
        user.save!
        reset_password_url = Rails.application.routes.url_helpers.edit_user_password_path(reset_password_token: raw)
        UserMailer.welcome_email(user,request.base_url+reset_password_url).deliver_now
        redirect_to staff_index_path, notice: 'Staff registered successfully!!', alert: "success"
      else
        redirect_to new_staff_path, notice: 'Something went wrong!!', alert: "danger"
      end
    rescue => error
      redirect_to new_staff_path, notice: error.message, alert: "danger"
    end
  end

  def show
  end

  def edit
    @roles = Role.all
  end

  def update
    begin
      @staff.update(user_params)
      redirect_to staff_index_path, notice: 'Staff updated successfully!!', alert: "success"
    rescue => error
      p error.message
      redirect_to staff_index_path, notice: error.message, alert: "danger"
    end

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
      params.permit(:id)
    end
    def find_staff
      @staff = User.find(params[:id]) if params[:id].present?
    end
    def check_admin
      if(current_user.role&.name != "ADMIN")
        redirect_to employee_index_path && return
      end
    end
end
