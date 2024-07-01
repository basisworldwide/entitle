class Integration < ApplicationRecord
  has_many :company_integration;
  has_many :employee_integration;
  has_many :company, :through => :company_integration
  has_many :employee, :through => :employee_integration
  has_many :app_intergration_details
end
