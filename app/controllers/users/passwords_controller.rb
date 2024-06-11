# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    user = User.where(email: params["user"]["email"]).first
    if user.present?
      user[:hash_visited] = false;
      user.save!
    end
    super
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    user = User.with_reset_password_token(params["reset_password_token"])
    if user.hash_visited
      redirect_to new_user_session_path , notice: 'Reset password link expired!!'
    end
    user[:hash_visited] = true;
    user.save!
    super
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    # Define a custom path after password reset
    signed_in_root_path(resource)
  end

  def after_sending_reset_password_instructions_path_for(resource_name)
    # Define a custom path after sending reset password instructions
    new_session_path(resource_name) if is_navigational_format?
  end
end
