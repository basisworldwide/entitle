class IntegrationController < ApplicationController

  def index
    @integrations = Integration.all
    @company_inetgrations = CompanyIntegration.find_by(company_id: current_user.company_id)
  end
end
