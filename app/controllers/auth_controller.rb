class AuthController < ApplicationController

  def new

  end

  def update_password
    begin
      is_valid_old_password = current_user.valid_password?(user_params[:password])
      if is_valid_old_password
        current_user.update(password: user_params[:new_password])
        redirect_to change_password_path , notice: 'Password changed successfully!!', alert: "success"
      else
        redirect_to change_password_path , notice: 'Please enter valid old password !!', alert: "danger"
      end
    rescue => error
      redirect_to change_password_path, notice: error.message, alert: "danger"
    end
  end

  private
  def user_params
    params.require(:user).permit(:password, :new_password)
  end
end
