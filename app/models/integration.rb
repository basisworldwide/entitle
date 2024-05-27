class Integration < ApplicationRecord
  has_many :company_integration;
  has_many :employee_integration;
end
