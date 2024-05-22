class ApplicationController < ActionController::Base

  def after_sign_in_path
    redirect_to dashboard_path
  end
end
